<?php

declare(strict_types=1);

namespace Decanet\Application;

use Closure;
use Decanet\Http\Request;
use Decanet\Http\Response;
use Decanet\Repository\LocationRepository;
use Decanet\Security\SessionAuthorizer;
use Decanet\View\Html;
use Decanet\View\TemplateRenderer;
use RuntimeException;

final class CatalogController
{
    /** @var array<string, array{title: string, parent: ?string, next: ?string, columns: int, locations: string}> */
    private const PAGES = [
        '/earth.php' => [
            'title' => 'Страны планеты Земля',
            'parent' => null,
            'next' => 'country',
            'columns' => 1,
            'locations' => 'countries',
        ],
        '/country.php' => [
            'title' => 'Регионы страны',
            'parent' => 'country',
            'next' => 'region',
            'columns' => 3,
            'locations' => 'regions',
        ],
        '/region.php' => [
            'title' => 'Города региона',
            'parent' => 'region',
            'next' => 'city',
            'columns' => 1,
            'locations' => 'cities',
        ],
        '/city.php' => [
            'title' => 'ВУЗы города',
            'parent' => 'city',
            'next' => 'school',
            'columns' => 1,
            'locations' => 'schools',
        ],
        '/school.php' => [
            'title' => 'Факультеты ВУЗа',
            'parent' => 'school',
            'next' => 'facultet',
            'columns' => 1,
            'locations' => 'facultets',
        ],
        '/facultet.php' => [
            'title' => 'Отделения факультета',
            'parent' => 'facultet',
            'next' => 'division',
            'columns' => 1,
            'locations' => 'divisions',
        ],
        '/division.php' => [
            'title' => 'Группы отделения',
            'parent' => 'division',
            'next' => 'sgroup',
            'columns' => 3,
            'locations' => 'groups',
        ],
    ];

    /** @var list<string> */
    private const SELECTION_LEVELS = [
        'country', 'region', 'city', 'school', 'facultet', 'division', 'sgroup', 'student',
    ];

    private ?LocationRepository $locations = null;

    /** @var null|Closure(): LocationRepository */
    private ?Closure $locationFactory = null;

    /** @var array<string, mixed> */
    private array $session;

    /**
     * @param LocationRepository|Closure(): LocationRepository $locations
     * @param array<string, mixed> $session
     */
    public function __construct(
        LocationRepository|Closure $locations,
        private readonly TemplateRenderer $renderer,
        array &$session,
        private readonly SessionAuthorizer $authorizer = new SessionAuthorizer(),
    ) {
        if ($locations instanceof LocationRepository) {
            $this->locations = $locations;
        } else {
            $this->locationFactory = $locations;
        }

        $this->session =& $session;
    }

    /** @return list<string> */
    public static function routes(): array
    {
        return array_keys(self::PAGES);
    }

    public function __invoke(Request $request): Response
    {
        if (!$this->authorizer->authorize($this->session)) {
            return Response::redirect('/login.php');
        }

        $page = self::PAGES[$request->path] ?? null;
        if ($page === null) {
            throw new RuntimeException('Unknown catalog route.');
        }

        $this->applySelection($request);
        $this->applyListFilter($request, $page);
        $locations = $this->locationsFor($page);

        return new Response($this->renderer->render('catalog.php', [
            'title' => $page['title'],
            'controls' => $this->controls($page),
            'table' => $this->locationTable($locations, $page['columns'], $page['next']),
            'menu' => $this->menu($page),
            'object' => $this->selectionHierarchy(),
            'message' => $this->flash('MESS', $request->query['mess'] ?? null),
            'error' => $this->flash('ERMESS', $request->query['ermess'] ?? null),
            'version' => Html::escape('версия 1.5' . (string) ($this->session['db_ver'] ?? '')),
            'styles' => $this->styles(),
        ]));
    }

    public function handles(Request $request): bool
    {
        if (!isset(self::PAGES[$request->path]) || $request->method !== 'GET') {
            return false;
        }
        if ($request->path === '/school.php') {
            return true;
        }

        $allowed = [
            'country_id', 'region_id', 'city_id', 'school_id', 'facultet_id', 'division_id',
            'sgroup_id', 'student_id', 'mess', 'ermess',
        ];
        if ($request->path === '/facultet.php') {
            $allowed[] = 'fac1m';
        }
        if ($request->path === '/division.php') {
            $allowed[] = 'div1m';
            if (($request->query['divm'] ?? null) === '0' || ($request->query['divm'] ?? null) === 0) {
                $allowed[] = 'divm';
            }
        }

        return array_diff(array_keys($request->query), $allowed) === [];
    }

    /**
     * @param array{parent: ?string, locations: string} $page
     * @return list<Location>
     */
    private function locationsFor(array $page): array
    {
        $parent = $page['parent'];
        if ($parent === null) {
            return $this->repository()->countries();
        }

        $parentId = $this->selectedId($parent);
        if ($parentId === null) {
            return [];
        }

        return match ($page['locations']) {
            'regions' => $this->repository()->regions($parentId),
            'cities' => $this->repository()->cities($parentId),
            'schools' => $this->repository()->schools($parentId),
            'facultets' => $this->repository()->facultets($parentId),
            'divisions' => $this->repository()->divisions($parentId, $this->activeFilter('fac1m')),
            'groups' => $this->repository()->groups($parentId, $this->activeFilter('div1m')),
            default => throw new RuntimeException('Unknown catalog location type.'),
        };
    }

    private function repository(): LocationRepository
    {
        if ($this->locations !== null) {
            return $this->locations;
        }

        if ($this->locationFactory === null) {
            throw new RuntimeException('Location repository is unavailable.');
        }

        return $this->locations = ($this->locationFactory)();
    }

    private function applySelection(Request $request): void
    {
        foreach (self::SELECTION_LEVELS as $index => $level) {
            $value = $request->query[$level . '_id'] ?? null;
            if (!$this->validId($value)) {
                continue;
            }

            if (!isset($this->session['du_' . $level])) {
                $this->session['co_' . $level] = (int) $value;
            }
            for ($next = $index + 1; $next < count(self::SELECTION_LEVELS); $next++) {
                $child = self::SELECTION_LEVELS[$next];
                if (!isset($this->session['du_' . $child])) {
                    unset($this->session['co_' . $child]);
                }
            }

            return;
        }
    }

    /** @param array{locations: string} $page */
    private function applyListFilter(Request $request, array $page): void
    {
        $key = match ($page['locations']) {
            'divisions' => 'fac1m',
            'groups' => 'div1m',
            default => null,
        };
        if ($key === null) {
            return;
        }

        $value = $request->query[$key] ?? null;
        if ((is_int($value) || is_string($value)) && in_array((string) $value, ['0', '1', '2'], true)) {
            $this->session[$key] = (int) $value;
        }
    }

    private function activeFilter(string $key): ?bool
    {
        return match ((int) ($this->session[$key] ?? 0)) {
            0 => true,
            1 => false,
            default => null,
        };
    }

    private function validId(mixed $value): bool
    {
        return (is_int($value) && $value > 0)
            || (is_string($value) && ctype_digit($value) && (int) $value > 0);
    }

    private function selectedId(string $level): ?int
    {
        $value = $this->session['co_' . $level] ?? null;

        return $this->validId($value) ? (int) $value : null;
    }

    /** @param list<Location> $locations */
    private function locationTable(array $locations, int $columns, ?string $next): string
    {
        $table = '<table width="100%">';
        $width = intdiv(100, $columns);
        $row = 0;
        foreach ($locations as $index => $location) {
            if ($index % $columns === 0) {
                $row++;
                $table .= '<tr>';
            }
            $color = $this->rowColor($location, $row);
            $number = $index + 1;
            $name = Html::escape($location->name);
            $href = $next === null
                ? ''
                : sprintf('%s.php?%s_id=%d', $next, $next, $location->id);
            $entry = $next === null ? $name : sprintf('<a href="%s">%s</a>', $href, $name);
            $table .= sprintf(
                '<td width="1%%" id="%s">%d</td><td width="%d%%" id="%s">%s</td>',
                $color,
                $number,
                $width,
                $color,
                $entry,
            );
            if (($index + 1) % $columns === 0) {
                $table .= '</tr>';
            }
        }

        $remainder = count($locations) % $columns;
        if ($remainder !== 0) {
            $color = $row % 2 === 0 ? 'col2' : 'col1';
            for ($column = $remainder; $column < $columns; $column++) {
                $table .= sprintf(
                    '<td width="1%%" id="%s"></td><td width="%d%%" id="%s"></td>',
                    $color,
                    $width,
                    $color,
                );
            }
            $table .= '</tr>';
        }

        return $table . '</table>';
    }

    private function rowColor(Location $location, int $row): string
    {
        if ($location->active === false) {
            return $row % 2 === 0 ? 'col4' : 'col3';
        }

        return $row % 2 === 0 ? 'col2' : 'col1';
    }

    private function selectionHierarchy(): string
    {
        $items = [];
        $countryId = $this->selectedId('country');
        if ($countryId === null) {
            return '';
        }
        $country = $this->find($this->repository()->countries(), $countryId);
        if ($country === null) {
            return '';
        }
        $items[] = ['level' => 'country', 'location' => $country];

        $regionId = $this->selectedId('region');
        if ($regionId === null) {
            return $this->breadcrumbs($items);
        }
        $region = $this->find($this->repository()->regions($countryId), $regionId);
        if ($region === null) {
            return $this->breadcrumbs($items);
        }
        $items[] = ['level' => 'region', 'location' => $region];

        $parents = [
            'city' => [$this->repository()->cities($regionId), $this->selectedId('city')],
            'school' => [null, $this->selectedId('school')],
            'facultet' => [null, $this->selectedId('facultet')],
            'division' => [null, $this->selectedId('division')],
            'sgroup' => [null, $this->selectedId('sgroup')],
        ];
        $parentId = $regionId;
        foreach ($parents as $level => [$locations, $selectedId]) {
            if ($selectedId === null) {
                break;
            }
            if ($locations === null) {
                $locations = match ($level) {
                    'school' => $this->repository()->schools($parentId),
                    'facultet' => $this->repository()->facultets($parentId),
                    'division' => $this->repository()->divisions($parentId),
                    'sgroup' => $this->repository()->groups($parentId),
                };
            }
            $location = $this->find($locations, $selectedId);
            if ($location === null) {
                break;
            }
            $items[] = ['level' => $level, 'location' => $location];
            $parentId = $selectedId;
        }

        return $this->breadcrumbs($items);
    }

    /** @param list<Location> $locations */
    private function find(array $locations, int $id): ?Location
    {
        foreach ($locations as $location) {
            if ($location->id === $id) {
                return $location;
            }
        }

        return null;
    }

    /** @param list<array{level: string, location: Location}> $items */
    private function breadcrumbs(array $items): string
    {
        $html = '';
        foreach ($items as $index => $item) {
            $level = $item['level'];
            $next = self::SELECTION_LEVELS[$index + 1] ?? null;
            $location = $item['location'];
            $name = Html::escape(
                in_array($level, ['school', 'facultet'], true) && $location->shortName !== null
                    ? $location->shortName
                    : $location->name,
            );
            if ($next === null || !isset($this->session['du_' . $next])) {
                $name = sprintf('<a href="%s.php">%s</a>', $level, $name);
            }
            $html .= $name . '.';
        }

        return $html;
    }

    /** @param array{locations: string} $page */
    private function menu(array $page): string
    {
        $basketCount = (int) ($this->session['baskc'] ?? 0);
        $objectRoute = $this->objectRoute();

        $menu = sprintf(
            '<a href="bask.php">Корзина(%d)</a><br><hr>'
            . '<a id="curhr" href="%s">Объект</a><br>'
            . '<a href="doc.php">Документы</a><br>'
            . '<a href="find.php">Поиск</a><br>'
            . '<a href="vvod.php">Ввод оценки</a><br>'
            . '<a href="admin.php">Пользователи</a><br><hr>'
            . '<a href="dnhelp.html">Помощь</a><br>'
            . '<a href="login.php">Выход</a><br>',
            $basketCount,
            $objectRoute,
        );

        return $menu . $this->legacyActions($page['locations']);
    }

    private function objectRoute(): string
    {
        foreach ([
            'country' => 'earth',
            'region' => 'country',
            'city' => 'region',
            'school' => 'city',
            'facultet' => 'school',
            'division' => 'facultet',
            'sgroup' => 'division',
        ] as $level => $route) {
            if ($this->selectedId($level) === null) {
                return $route . '.php';
            }
        }

        return 'student.php';
    }

    /** @param array{locations: string} $page */
    private function controls(array $page): string
    {
        return match ($page['locations']) {
            'divisions' => $this->filterMenu('fac1m', 'Отделения:'),
            'groups' => $this->divisionControls() . $this->filterMenu('div1m', 'Группы:'),
            default => '',
        };
    }

    private function divisionControls(): string
    {
        return '<table width="100%"><tr><td id="page"><b>Отделение:</b></td>'
            . '<td id="curhr"><a id="curhr" href="division.php?divm=0">состав</a></td>'
            . '<td id="page"><a href="division.php?divm=1">программа</a></td>'
            . '<td width="100%" id="page"></td></tr></table>';
    }

    private function filterMenu(string $key, string $title): string
    {
        $selected = (int) ($this->session[$key] ?? 0);
        $items = ['активные', 'выпущенные', 'все'];
        $html = sprintf('<table width="100%%"><tr><td id="page"><b>%s</b></td>', $title);
        foreach ($items as $index => $item) {
            $id = $index === $selected ? 'curhr' : 'page';
            $html .= sprintf(
                '<td id="%s"><a%s href="%s.php?%s=%d">%s</a></td>',
                $id,
                $id === 'curhr' ? ' id="curhr"' : '',
                $key === 'fac1m' ? 'facultet' : 'division',
                $key,
                $index,
                $item,
            );
        }

        return $html . '<td width="100%" id="page"></td></tr></table>';
    }

    private function legacyActions(string $locations): string
    {
        return match ($locations) {
            'divisions' => '<a href="facultet.php?cont=1&excel=1">Контингент (Excel)</a><br>'
                . '<a href="facultet.php?cont=1">Контингент</a><br>'
                . '<a href="facultet.php?itog=1&excel=1">Итоги (Excel)</a><br>'
                . '<a href="facultet.php?itog=1">Итоги</a><br><br>'
                . '<a href="facultet.php?divadd=1">Добавить отделение</a><br>',
            'groups' => '<a href="division.php?add=1">Добавить группу</a><br>'
                . '<a href="division.php?vipusk=1">Выпуск</a><br>'
                . '<a href="division.php?nextkurs=1">След. курс</a><br><br>'
                . '<a href="division.php?dived=1">Изменить отделение</a><br>',
            default => '',
        };
    }

    private function flash(string $key, mixed $override): string
    {
        $value = null;
        if (isset($this->session[$key])) {
            $value = $this->session[$key];
            unset($this->session[$key]);
        }
        if ($override !== null) {
            $value = $override;
        }

        return Html::escape(is_scalar($value) ? (string) $value : '');
    }

    private function theme(): int
    {
        $theme = $this->session['du_themes'] ?? 1;

        return $this->validId($theme) ? (int) $theme : 1;
    }

    private function styles(): string
    {
        $file = dirname(__DIR__, 2) . '/public/themes/' . $this->theme() . '/style.css';
        $styles = is_file($file) ? file_get_contents($file) : false;

        return is_string($styles) ? $styles : '';
    }
}
