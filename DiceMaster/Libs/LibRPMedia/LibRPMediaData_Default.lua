local LRPM12 = LibStub and LibStub:GetLibrary("LibRPMedia-1.2", true);

if not LRPM12 or LRPM12.db ~= nil then
    return;
end

LRPM12.db = {
    icons = {
        size = 0,
        id   = {},
        name = {},
    },
    music = {
        size = 0,
        file = {},
        name = {},
        nkey = {},
        time = {},
    },
};
