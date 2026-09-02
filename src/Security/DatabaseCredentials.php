<?php

declare(strict_types=1);

namespace Decanet\Security;

final readonly class DatabaseCredentials
{
    public function __construct(
        public string $user,
        public string $password,
    ) {
    }
}
