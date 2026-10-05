<?php

declare(strict_types=1);

namespace Decanet\Security;

final class LoginFailureMessage
{
    /** @return array{heading: string, error: string}|null */
    public static function for(bool $csrfFailure, bool $authenticationUnavailable, bool $twoFactorFailure): ?array
    {
        if ($csrfFailure) {
            return [
                'heading' => 'Форма устарела. Обновите страницу и повторите вход.',
                'error' => 'Проверка защищённой формы не пройдена. Обновите страницу и повторите вход.',
            ];
        }

        if ($authenticationUnavailable) {
            return [
                'heading' => 'Авторизация временно недоступна.',
                'error' => 'Не удалось проверить учётные данные. Проверьте подключение к базе данных и журнал ошибок сервера.',
            ];
        }

        if ($twoFactorFailure) {
            return [
                'heading' => 'Введите новый разовый код и повторите вход.',
                'error' => 'Разовый код не прошёл проверку.',
            ];
        }

        return null;
    }
}
