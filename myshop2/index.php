<?php
// Set the path to your Django project
$django_path = __DIR__;

// Set the path to Python executable (if available)
$python_path = '/usr/local/bin/python3';

// Set the path to your Django project's manage.py
$manage_py = $django_path . '/manage.py';

// Set the path to your Django project's settings
$settings = 'myshop.settings';

// Run the Django development server
$command = "$python_path $manage_py runserver 127.0.0.1:8000 --settings=$settings";
exec($command . " > /dev/null 2>&1 &");

// Forward the request to the Django server
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "http://127.0.0.1:8000" . $_SERVER['REQUEST_URI']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_HEADER, true);

// Forward all headers
$headers = getallheaders();
foreach ($headers as $key => $value) {
    curl_setopt($ch, CURLOPT_HTTPHEADER, array("$key: $value"));
}

// Forward the request method
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $_SERVER['REQUEST_METHOD']);

// Forward POST data
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    curl_setopt($ch, CURLOPT_POSTFIELDS, file_get_contents('php://input'));
}

$response = curl_exec($ch);
$header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
$header = substr($response, 0, $header_size);
$body = substr($response, $header_size);

// Forward the response headers
$headers = explode("\n", $header);
foreach ($headers as $header) {
    if (trim($header) !== '') {
        header($header);
    }
}

// Output the response body
echo $body;

curl_close($ch);
?> 