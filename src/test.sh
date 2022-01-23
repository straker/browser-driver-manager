export http_proxy="http://localhost:8080"
export https_proxy="https://127.0.0.1:8080"

# curl --proxy-insecure 'https://stevenklambert.com'

curl --location --retry 3 --silent --fail 'http://foo.com/package.json'