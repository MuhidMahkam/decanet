<?php

declare(strict_types=1);

namespace Decanet\Infrastructure;

final class DatabaseErrorMessage
{
    public static function forCode(int $code): string
    {
        return $code === 1370
            ? 'Доступ к операции запрещен.'
            : 'Ошибка выполнения операции. Проверьте поля, обязательные для заполнения.';
    }
}
