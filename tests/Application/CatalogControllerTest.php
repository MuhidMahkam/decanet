<?php

declare(strict_types=1);

namespace Decanet\Tests\Application;

use Decanet\Application\CatalogController;
use Decanet\Application\Location;
use Decanet\Http\Request;
use Decanet\Repository\LocationRepository;
use Decanet\Security\SessionAuthorizer;
use Decanet\View\TemplateRenderer;
use PHPUnit\Framework\TestCase;

final class CatalogControllerTest extends TestCase
{
    protected function tearDown(): void
    {
        $_SERVER = [];
        $_GET = [];
        $_POST = [];
    }

    public function testItRendersTheLegacyLayoutAndSelectedRegionCities(): void
    {
        $session = [
            'du_id' => 7,
            'expire' => 101,
            'du_themes' => 1,
            'co_country' => 1,
            'co_region' => 99,
            'co_city' => 100,
        ];
        $controller = $this->controller($session);

        $response = $controller($this->request('/region.php', ['region_id' => '10']));

        self::assertSame(200, $response->status);
        self::assertSame(10, $session['co_region']);
        self::assertArrayNotHasKey('co_city', $session);
        self::assertSame(1_000, $session['expire']);
        self::assertStringContainsString('<table id="menu"', $response->body);
        self::assertStringContainsString('<td id="prochead">Города региона</td>', $response->body);
        self::assertStringContainsString('<a href="city.php?city_id=100">Москва</a>', $response->body);
        self::assertStringContainsString(
            '<a href="country.php">Россия</a>.<a href="region.php">Московская область</a>.',
            $response->body,
        );
        self::assertStringContainsString('<style>', $response->body);
    }

    public function testItListsSchoolsFromTheCityCatalog(): void
    {
        $session = [
            'du_id' => 7,
            'expire' => 101,
            'co_country' => 1,
            'co_region' => 10,
            'co_city' => 100,
        ];
        $controller = $this->controller($session);

        $response = $controller($this->request('/city.php'));

        self::assertSame(200, $response->status);
        self::assertStringContainsString('<a href="school.php?school_id=501">МГУ</a>', $response->body);
    }

    public function testItMigratesSchoolFacultetAndDivisionReadOnlyCatalogs(): void
    {
        $session = [
            'du_id' => 7,
            'expire' => 101,
            'co_country' => 1,
            'co_region' => 10,
            'co_city' => 100,
            'co_school' => 501,
            'co_facultet' => 601,
            'co_division' => 701,
        ];
        $controller = $this->controller($session);

        $school = $controller($this->request('/school.php'));
        $facultet = $controller($this->request('/facultet.php', ['fac1m' => '2']));
        $division = $controller($this->request('/division.php', ['div1m' => '1']));

        self::assertStringContainsString('<a href="facultet.php?facultet_id=601">Физический факультет</a>', $school->body);
        self::assertStringContainsString('<a href="division.php?division_id=701">Кафедра физики</a>', $facultet->body);
        self::assertStringContainsString('Отделения:', $facultet->body);
        self::assertStringContainsString('<a href="sgroup.php?sgroup_id=801">Ф-101 (2024/2028)</a>', $division->body);
        self::assertStringContainsString('Отделение:', $division->body);
        self::assertStringContainsString('Добавить группу', $division->body);
        self::assertStringContainsString(
            '<a href="school.php">МГУ</a>.<a href="facultet.php">Физ</a>.<a href="division.php">Кафедра физики</a>.',
            $division->body,
        );
    }

    public function testItOnlyHandlesReadOnlyMigratedRequests(): void
    {
        $session = ['du_id' => 7, 'expire' => 101];
        $controller = $this->controller($session);

        self::assertTrue($controller->handles($this->request('/school.php', ['unexpected' => '1'])));
        self::assertTrue($controller->handles($this->request('/facultet.php', ['fac1m' => '1'])));
        self::assertTrue($controller->handles($this->request('/division.php', ['divm' => '0', 'div1m' => '2'])));
        self::assertFalse($controller->handles($this->request('/facultet.php', ['cont' => '1'])));
        self::assertFalse($controller->handles($this->request('/division.php', ['divm' => '1'])));

        $programSession = ['du_id' => 7, 'expire' => 101, 'divm' => 1];
        $programController = $this->controller($programSession);
        self::assertFalse($programController->handles($this->request('/division.php')));
        self::assertTrue($programController->handles($this->request('/division.php', ['divm' => '0'])));
    }

    public function testItEscapesCatalogNames(): void
    {
        $session = ['du_id' => 7, 'expire' => 101];
        $repository = new class implements LocationRepository {
            public function countries(): array
            {
                return [new Location(1, '<script>alert("x")</script>', 'X')];
            }

            public function regions(int $countryId): array
            {
                return [];
            }

            public function cities(int $regionId): array
            {
                return [];
            }

            public function schools(int $cityId): array
            {
                return [];
            }

            public function facultets(int $schoolId): array
            {
                return [];
            }

            public function divisions(int $facultetId, ?bool $active = null): array
            {
                return [];
            }

            public function groups(int $divisionId, ?bool $active = null): array
            {
                return [];
            }
        };
        $controller = $this->controller($session, $repository);

        $response = $controller($this->request('/earth.php'));

        self::assertStringNotContainsString('<script>alert("x")</script>', $response->body);
        self::assertStringContainsString('&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;', $response->body);
    }

    public function testItPreservesLockedSelectionsWhileClearingUnlockedDescendants(): void
    {
        $session = [
            'du_id' => 7,
            'expire' => 101,
            'du_country' => 1,
            'co_country' => 1,
            'co_region' => 10,
            'co_city' => 100,
        ];
        $controller = $this->controller($session);

        $controller($this->request('/earth.php', ['country_id' => '2']));

        self::assertSame(1, $session['co_country']);
        self::assertArrayNotHasKey('co_region', $session);
        self::assertArrayNotHasKey('co_city', $session);
    }

    public function testItRedirectsUnauthorizedRequestsWithoutOpeningTheRepository(): void
    {
        $session = [];
        $opened = false;
        $controller = $this->controller(
            $session,
            static function () use (&$opened): LocationRepository {
                $opened = true;

                throw new \LogicException('The repository must not be opened.');
            },
        );

        $response = $controller($this->request('/earth.php'));

        self::assertSame(302, $response->status);
        self::assertSame('/login.php', $response->headers['Location']);
        self::assertFalse($opened);
    }

    public function testItMarksExpiredSessionsForTheLegacyLoginFlow(): void
    {
        $session = ['du_id' => 7, 'expire' => 99];
        $controller = $this->controller($session);

        $response = $controller($this->request('/earth.php'));

        self::assertSame(302, $response->status);
        self::assertSame(7, $session['expired_du_id']);
        self::assertArrayNotHasKey('du_id', $session);
    }

    /** @param array<string, mixed> $session */
    private function controller(array &$session, LocationRepository|\Closure|null $locations = null): CatalogController
    {
        return new CatalogController(
            $locations ?? $this->repository(),
            new TemplateRenderer(dirname(__DIR__, 2) . '/templates'),
            $session,
            new SessionAuthorizer(900, static fn (): int => 100),
        );
    }

    private function request(string $path, array $query = []): Request
    {
        $_SERVER['REQUEST_METHOD'] = 'GET';
        $_SERVER['REQUEST_URI'] = $path;
        $_GET = $query;

        return Request::fromGlobals();
    }

    private function repository(): LocationRepository
    {
        return new class implements LocationRepository {
            public function countries(): array
            {
                return [
                    new Location(1, 'Россия', 'РФ'),
                    new Location(2, 'Беларусь', 'РБ'),
                ];
            }

            public function regions(int $countryId): array
            {
                return $countryId === 1 ? [new Location(10, 'Московская область')] : [];
            }

            public function cities(int $regionId): array
            {
                return $regionId === 10 ? [new Location(100, 'Москва')] : [];
            }

            public function schools(int $cityId): array
            {
                return $cityId === 100 ? [new Location(501, 'МГУ')] : [];
            }

            public function facultets(int $schoolId): array
            {
                return $schoolId === 501 ? [new Location(601, 'Физический факультет', 'Физ')] : [];
            }

            public function divisions(int $facultetId, ?bool $active = null): array
            {
                return $facultetId === 601
                    ? [new Location(701, 'Кафедра физики', null, $active ?? true)]
                    : [];
            }

            public function groups(int $divisionId, ?bool $active = null): array
            {
                return $divisionId === 701 ? [new Location(801, 'Ф-101 (2024/2028)', null, $active ?? true)] : [];
            }
        };
    }
}
