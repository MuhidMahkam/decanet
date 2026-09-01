<?php

declare(strict_types=1);

namespace Decanet\Repository;

use mysqli;
use mysqli_result;
use RuntimeException;

final class StoredProcedureRepository
{
    public function __construct(private readonly mysqli $connection, private readonly string $database)
    {
    }

    /** @param list<int|float|string|null> $parameters */
    /** @return list<array<string, mixed>> */
    public function call(string $procedure, array $parameters = []): array
    {
        if (preg_match('/^[A-Z][A-Z0-9_]*$/', $procedure) !== 1) {
            throw new RuntimeException('Invalid stored procedure name.');
        }

        $placeholders = implode(', ', array_fill(0, count($parameters), '?'));
        $statement = $this->connection->prepare(sprintf('CALL `%s`.`%s`(%s)', $this->database, $procedure, $placeholders));
        if ($statement === false) {
            throw new RuntimeException('Unable to prepare stored procedure.');
        }
        if ($parameters !== []) {
            $types = '';
            $bound = [];
            foreach ($parameters as $index => $parameter) {
                $types .= is_int($parameter) ? 'i' : (is_float($parameter) ? 'd' : 's');
                $bound[$index] = $parameter;
            }
            $statement->bind_param($types, ...$bound);
        }
        $statement->execute();
        $result = $statement->get_result();
        $rows = $result instanceof mysqli_result ? $result->fetch_all(MYSQLI_ASSOC) : [];
        while ($this->connection->more_results() && $this->connection->next_result()) {
        }
        $statement->close();

        return $rows;
    }
}
