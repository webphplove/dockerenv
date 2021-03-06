<?php
// from http://gearman.org/examples/reverse/

/*
NOTICE:
    Please run `php gearman-worker.php` at command, before run the file.
 */

// Create our client object
$client = new GearmanClient();

// Add a server
$client->addServer('gearman'); // by default host/port will be "localhost" & 4730

//var_dump($client->ping('test'), $client);die;

echo "Sending job\n";

// Send reverse job
$result = $client->doNormal("reverse", "Hello!");

if ($result) {
  echo "Success: $result\n";
} else {
     echo "Failure: $result\n";
}

