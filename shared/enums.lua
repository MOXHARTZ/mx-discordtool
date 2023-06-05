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
    GetUserByDiscord = 100,
    GetUsers = 101,
    GetUserById = 102,
    BanUser = 103,
    Screenshot = 104,
    KickUser = 105,
    Wipe = 106,
    Revive = 107,
    Kill = 108,
    SetCoords = 109,
    ToggleWhitelist = 110,
}
