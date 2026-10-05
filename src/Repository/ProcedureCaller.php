<?php

declare(strict_types=1);

namespace Decanet\Repository;

interface ProcedureCaller
{
    /** @param list<int|float|string|null> $parameters */
    /** @return list<array<string, mixed>> */
    public function call(string $procedure, array $parameters = []): array;
}
