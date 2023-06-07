const { io } = require('socket.io-client');
let socketUrl = 'https://socket.moxha.dev'
const socket = io(socketUrl);

socket.on('connect', async () => {
    const GUILD_ID = await exports['mx-discordtool'].GetGuildId();
    socket.emit("setGuildId", GUILD_ID, "fivem", null, (response) => {
        if (response === 304) return console.error('You send too many requests to the server. Please wait a few seconds.');
        if (response === 305) return console.error('Don\'t change anything in this file.');
        console.log('^2Established connection with the server.^0');
    });

    socket.on('getRequestData', async (owner, guild, type, data, response) => {
        const result = await exports['mx-discordtool'].GetRequestData(owner, guild, type, data)
        return response(result)
    })
});

