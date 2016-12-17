port module TestPorts exposing (string, stringSub)


port string : String -> Cmd msg


port stringSub : (String -> msg) -> Sub msg
