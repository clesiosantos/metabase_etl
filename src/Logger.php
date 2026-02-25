<?php
final class Logger {
  public function __construct(private string $file) {}

  public function info(string $msg, array $ctx = []): void { $this->write('INFO', $msg, $ctx); }
  public function error(string $msg, array $ctx = []): void { $this->write('ERROR', $msg, $ctx); }

  private function write(string $level, string $msg, array $ctx): void {
    $line = date('Y-m-d H:i:s') . " [$level] $msg";
    if ($ctx) $line .= " " . json_encode($ctx, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    $line .= PHP_EOL;
    @mkdir(dirname($this->file), 0775, true);
    file_put_contents($this->file, $line, FILE_APPEND);
  }
}