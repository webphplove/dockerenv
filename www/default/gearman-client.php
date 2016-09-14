<?php
// from http://gearman.org/examples/reverse/
// Create our client object
$client = new GearmanClient();
//var_dump($_SERVER);die;

// Add a server
$client->addServer('gearman'); // by default host/port will be "localhost" & 4730

echo "Sending job\n";

// Send reverse job
$result = $client->doNormal("reverse", "Hello!");

if ($result) {
  echo "Success: $result\n";
}

