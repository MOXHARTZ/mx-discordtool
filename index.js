const { io } = require('socket.io-client');
// let socketUrl = 'https://socket.moxha.net'
let socketUrl = 'http://127.0.0.1:3001'
// if (process.env.NODE_ENV == 'development') socketUrl = 'http://localhost:3001';
const socket = io(socketUrl);
const GUILD_ID = '720326694271189124';

socket.on('connect', (socket) => {
    console.log('^2Connected to socket^0');
});

socket.emit("setGuildId", GUILD_ID, "fivem", null, (response) => {
    if (response === 305) return console.log('Don\'t change anything in this file.');
    console.log('^2Connected to guild^0');
});

socket.on('getRequestData', async (owner, guild, type, data, response) => {
    const result = await exports['mx-discordtool'].GetRequestData(owner, guild, type, data)
    return response(result)
})