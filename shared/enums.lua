-- ! Developer Note: Please don't change these values, they are storaged in the api.

--- @enum StatusEnum
StatusEnum = {
    WaitingForCallback = 1,
    Callback = 2,
    Finished = 3,
    Error = 4,
}

--- @enum TypeEnum
TypeEnum = {
    GetUser = 100,
    GetUsers = 101,
    GetUserById = 102,
    BanUser = 103,
}
