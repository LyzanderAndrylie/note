module example.com

go 1.27.1

replace github.com/nyaruka/phonenumbers/v2 => ../code

require github.com/nyaruka/phonenumbers/v2 v2.0.0

require google.golang.org/protobuf v1.36.11 // indirect
