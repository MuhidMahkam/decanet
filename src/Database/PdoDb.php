<?php
declare(strict_types=1);

namespace decanet\Database;

use PDO;
use PDOException;

class PdoDb
{
    private PDO $pdo;

    public function __construct(array $cfg)
    {
        $dsn = sprintf(
            'mysql:host=%s;port=%s;dbname=%s;charset=%s',
            $cfg['host'] ?? '127.0.0.1',
            $cfg['port'] ?? '3306',
            $cfg['db'] ?? '',
            $cfg['charset'] ?? 'utf8mb4'
        );

        $this->pdo = new PDO($dsn, $cfg['user'] ?? 'root', $cfg['pass'] ?? '', [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
    }

    public function pdo(): PDO
    {
        return $this->pdo;
    }

    /**
     * Call stored procedure and return first resultset.
     */
    public function callProcedure(string $proc, array $params = []): array
    {
        $placeholders = implode(',', array_fill(0, count($params), '?'));
        $sql = $placeholders === '' ? "CALL {$proc}()" : "CALL {$proc}({$placeholders})";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(array_values($params));
        $rows = $stmt->fetchAll();
        // consume remaining resultsets if any
        while ($stmt->nextRowset()) { /* noop */ }
        return $rows;
    }

    /**
     * Execute procedure without returning rows.
     */
    public function execProcedure(string $proc, array $params = []): void
    {
        $placeholders = implode(',', array_fill(0, count($params), '?'));
        $sql = $placeholders === '' ? "CALL {$proc}()" : "CALL {$proc}({$placeholders})";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(array_values($params));
        while ($stmt->nextRowset()) { /* noop */ }
    }
}