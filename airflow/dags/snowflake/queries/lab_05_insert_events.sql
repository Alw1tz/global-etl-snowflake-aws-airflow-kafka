INSERT INTO {source} VALUES
(1, 'CLICK',    PARSE_JSON('{{"user": "alice",  "page": "/home"}}')),
(2, 'PURCHASE', PARSE_JSON('{{"user": "bob",    "amount": 99.99}}')),
(3, 'LOGIN',    PARSE_JSON('{{"user": "carlos", "ip": "10.0.0.1"}}'))
