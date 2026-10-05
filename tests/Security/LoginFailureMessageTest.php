<?php

declare(strict_types=1);

namespace Decanet\Tests\Security;

use Decanet\Security\LoginFailureMessage;
use PHPUnit\Framework\TestCase;

final class LoginFailureMessageTest extends TestCase
{
    public function testItExplainsRejectedCsrfTokens(): void
    {
        self::assertSame(
            [
                'heading' => 'Форма устарела. Обновите страницу и повторите вход.',
                'error' => 'Проверка защищённой формы не пройдена. Обновите страницу и повторите вход.',
            ],
            LoginFailureMessage::for(true, false, false),
        );
    }

    public function testItDistinguishesUnavailableLookupFromRejectedCredentials(): void
    {
        self::assertSame(
            [
                'heading' => 'Авторизация временно недоступна.',
                'error' => 'Не удалось проверить учётные данные. Проверьте подключение к базе данных и журнал ошибок сервера.',
            ],
            LoginFailureMessage::for(false, true, false),
        );
        self::assertNull(LoginFailureMessage::for(false, false, false));
    }

    public function testItExplainsRejectedTwoFactorCode(): void
    {
        self::assertSame(
            [
                'heading' => 'Введите новый разовый код и повторите вход.',
                'error' => 'Разовый код не прошёл проверку.',
            ],
            LoginFailureMessage::for(false, false, true),
        );
    }
}
