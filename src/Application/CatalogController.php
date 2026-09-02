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
        $locations = $this->locationsFor($page);

        return new Response($this->renderer->render('catalog.php', [
            'title' => $page['title'],
            'table' => $this->locationTable($locations, $page['columns'], $page['next']),
            'menu' => $this->menu(),
            'object' => $this->selectionHierarchy(),
            'message' => $this->flash('MESS', $request->query['mess'] ?? null),
            'error' => $this->flash('ERMESS', $request->query['ermess'] ?? null),
            'version' => Html::escape('версия 1.5' . (string) ($this->session['db_ver'] ?? '')),
            'styles' => $this->styles(),
        ]));
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
            $color = $row % 2 === 0 ? 'col2' : 'col1';
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

        $cityId = $this->selectedId('city');
        if ($cityId !== null && ($city = $this->find($this->repository()->cities($regionId), $cityId)) !== null) {
            $items[] = ['level' => 'city', 'location' => $city];
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
            $name = Html::escape($item['location']->name);
            if ($next === null || !isset($this->session['du_' . $next])) {
                $name = sprintf('<a href="%s.php">%s</a>', $level, $name);
            }
            $html .= $name . '.';
        }

        return $html;
    }

    private function menu(): string
    {
        $basketCount = (int) ($this->session['baskc'] ?? 0);
        $objectRoute = $this->objectRoute();

        return sprintf(
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
    }

    private function objectRoute(): string
    {
        foreach (['country' => 'earth', 'region' => 'country', 'city' => 'region', 'school' => 'city'] as $level => $route) {
            if ($this->selectedId($level) === null) {
                return $route . '.php';
            }
        }

        return 'student.php';
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
