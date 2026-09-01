<?php

declare(strict_types=1);

namespace Decanet\Tests\Http;

use Decanet\Http\Request;
use PHPUnit\Framework\TestCase;

final class RequestTest extends TestCase
{
    protected function tearDown(): void
    {
        $_SERVER = [];
        $_GET = [];
        $_POST = [];
    }

    public function testItBuildsRequestFromGlobalsWithoutQueryInPath(): void
    {
        $_SERVER['REQUEST_METHOD'] = 'post';
        $_SERVER['REQUEST_URI'] = '/student.php?page=2';
        $_GET = ['page' => '2'];
        $_POST = ['name' => 'Ada'];

        $request = Request::fromGlobals();

        self::assertSame('POST', $request->method);
        self::assertSame('/student.php', $request->path);
        self::assertSame(['page' => '2'], $request->query);
        self::assertSame(['name' => 'Ada'], $request->post);
    }
}
