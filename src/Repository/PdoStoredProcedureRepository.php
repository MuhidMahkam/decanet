<?php

declare(strict_types=1);

namespace Decanet\Repository;

use PDO;
use RuntimeException;

final class PdoStoredProcedureRepository implements ProcedureCaller
{
    public function __construct(private readonly PDO $connection, private readonly string $database)
    {
        if (preg_match('/^[a-zA-Z][a-zA-Z0-9_]*$/', $database) !== 1) {
            throw new RuntimeException('Invalid database name.');
        }
    }

    /** @param list<int|float|string|null> $parameters */
    /** @return list<array<string, mixed>> */
    public function call(string $procedure, array $parameters = []): array
    {
        if (preg_match('/^[A-Z][A-Z0-9_]*$/', $procedure) !== 1) {
            throw new RuntimeException('Invalid stored procedure name.');
        }

        $placeholders = implode(', ', array_fill(0, count($parameters), '?'));
        $statement = $this->connection->prepare(
            sprintf('CALL `%s`.`%s`(%s)', $this->database, $procedure, $placeholders),
        );
        if ($statement === false) {
            throw new RuntimeException('Unable to prepare stored procedure.');
        }

        $statement->execute($parameters);
        $rows = $statement->fetchAll(PDO::FETCH_ASSOC);
        while ($statement->nextRowset()) {
        }
        $statement->closeCursor();

        return $rows;
    }
}
