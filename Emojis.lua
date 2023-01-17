-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Emoji integration.
--

local Me = DiceMaster4
local Profile = Me.Profile

local Emoji_IncompleteRegex = ":[^:][^:]+$";
local Emoji_CompleteRegex = ":[^:]+:";

local CHAT_MSG_TYPES = {
    "AFK",
    "BATTLEGROUND_LEADER",
    "BATTLEGROUND",
    "CHANNEL",
    "DND",
    "EMOTE",
    "GUILD",
    "OFFICER",
    "PARTY_LEADER",
    "PARTY",
    "RAID_LEADER",
    "RAID_WARNING",
    "RAID",
    "SAY",
    "WHISPER",
    "WHISPER_INFORM",
    "BN_WHISPER",
    "BN_WHISPER_INFORM",
    "YELL",
};

Me.EmojiList = {
	[":angry:"] = "Angry",
	[":anubarakangry:"] = "Anubarak_Angry",
	[":anubarakcool:"] = "Anubarak_Cool",
	[":anubarakhappy:"] = "Anubarak_Happy",
	[":anubaraklove:"] = "Anubarak_Love",
	[":anubarakmeh:"] = "Anubarak_Meh",
	[":anubarakoops:"] = "Anubarak_Oops",
	[":anubarakrofl:"] = "Anubarak_ROFL",
	[":anubaraksad:"] = "Anubarak_Sad",
	[":anubaraksilly:"] = "Anubarak_Silly",
	[":anubarakwow:"] = "Anubarak_Surprised",
	[":clap:"] = "Applause",
	[":arthasangry:"] = "Arthas_Angry",
	[":arthascool:"] = "Arthas_Cool",
	[":arthashappy:"] = "Arthas_Happy",
	[":arthaslove:"] = "Arthas_Love",
	[":arthasmeh:"] = "Arthas_Meh",
	[":arthasoops:"] = "Arthas_Oops",
	[":arthasrofl:"] = "Arthas_ROFL",
	[":arthassad:"] = "Arthas_Sad",
	[":arthassilly:"] = "Arthas_Silly",
	[":arthaswow:"] = "Arthas_Surprised",
	[":noodles:"] = "Bowl_of_Noodles",
	[":brightwingangry:"] = "Brightwing_Angry",
	[":brightwingcool:"] = "Brightwing_Cool",
	[":brightwinghappy:"] = "Brightwing_Happy",
	[":brightwinglove:"] = "Brightwing_Love",
	[":brightwingmeh:"] = "Brightwing_Meh",
	[":brightwingoops:"] = "Brightwing_Oops",
	[":brightwingrofl:"] = "Brightwing_ROFL",
	[":brightwingsad:"] = "Brightwing_Sad",
	[":brightwingsilly:"] = "Brightwing_Silly",
	[":brightwingwow:"] = "Brightwing_Surprised",
	[":cheers:"] = "Cheers",
	[":cheese:"] = "Cheese",
	[":chenangry:"] = "Chen_Angry",
	[":chencool:"] = "Chen_Cool",
	[":chenhappy:"] = "Chen_Happy",
	[":chenlove:"] = "Chen_Love",
	[":chenmeh:"] = "Chen_Meh",
	[":chenoops:"] = "Chen_Oops",
	[":chenrofl:"] = "Chen_ROFL",
	[":chensad:"] = "Chen_Sad",
	[":chensilly:"] = "Chen_Silly",
	[":chenwow:"] = "Chen_Surprised",
	[":choangry:"] = "Cho_Angry",
	[":chocool:"] = "Cho_Cool",
	[":chohappy:"] = "Cho_Happy",
	[":cholove:"] = "Cho_Love",
	[":chomeh:"] = "Cho_Meh",
	[":chooops:"] = "Cho_Oops",
	[":chorofl:"] = "Cho_ROFL",
	[":chosad:"] = "Cho_Sad",
	[":chosilly:"] = "Cho_Silly",
	[":chowow:"] = "Cho_Surprised",
	[":chromieangry:"] = "Chromie_Angry",
	[":chromiecool:"] = "Chromie_Cool",
	[":chromiehappy:"] = "Chromie_Happy",
	[":chromielove:"] = "Chromie_Love",
	[":chromiemeh:"] = "Chromie_Meh",
	[":chromieoops:"] = "Chromie_Oops",
	[":chromierofl:"] = "Chromie_ROFL",
	[":chromiesad:"] = "Chromie_Sad",
	[":chromiesilly:"] = "Chromie_Silly",
	[":chromiewow:"] = "Chromie_Surprised",
	[":coffin:"] = "Coffin",
	[":cool:"] = "Cool",
	[":tt:"] = "Cry",
	[":etcangry:"] = "ETC_Angry",
	[":etccool:"] = "ETC_Cool",
	[":etchappy:"] = "ETC_Happy",
	[":etclove:"] = "ETC_Love",
	[":etcmeh:"] = "ETC_Meh",
	[":etcoops:"] = "ETC_Oops",
	[":etcrofl:"] = "ETC_ROFL",
	[":etcsad:"] = "ETC_Sad",
	[":etcsilly:"] = "ETC_Silly",
	[":etcwow:"] = "ETC_Surprised",
	[":falstadangry:"] = "Falstad_Angry",
	[":falstadcool:"] = "Falstad_Cool",
	[":falstadhappy:"] = "Falstad_Happy",
	[":falstadlove:"] = "Falstad_Love",
	[":falstadmeh:"] = "Falstad_Meh",
	[":falstadoops:"] = "Falstad_Oops",
	[":falstadrofl:"] = "Falstad_ROFL",
	[":falstadsad:"] = "Falstad_Sad",
	[":falstadsilly:"] = "Falstad_Silly",
	[":falstadwow:"] = "Falstad_Surprised",
	[":fingerx:"] = "Fingers_Crossed",
	[":flex:"] = "Flex",
	[":gallangry:"] = "Gall_Angry",
	[":gallcool:"] = "Gall_Cool",
	[":gallhappy:"] = "Gall_Happy",
	[":galllove:"] = "Gall_Love",
	[":gallmeh:"] = "Gall_Meh",
	[":galloops:"] = "Gall_Oops",
	[":gallrofl:"] = "Gall_ROFL",
	[":gallsad:"] = "Gall_Sad",
	[":gallsilly:"] = "Gall_Silly",
	[":gallwow:"] = "Gall_Surprised",
	[":gclap:"] = "Gauntlet_Applause",
	[":gfingerx:"] = "Gauntlet_Fingers_Crossed",
	[":gflex:"] = "Gauntlet_Flex",
	[":ghangloose:"] = "Gauntlet_Hang_Loose",
	[":grockon:"] = "Gauntlet_Keep_Rockin",
	[":gpaper:"] = "Gauntlet_Paper",
	[":gpoint:"] = "Gauntlet_Point",
	[":gfistbump:"] = "Gauntlet_Pound_It",
	[":grock:"] = "Gauntlet_Rock",
	[":gscissors:"] = "Gauntlet_Scissors",
	[":ghandshake:"] = "Gauntlet_Shake",
	[":gtauren:"] = "Gauntlet_Tauren",
	[":gn:"] = "Gauntlet_Thumbs_Down",
	[":gy:"] = "Gauntlet_Thumbs_Up",
	[":gzerg:"] = "Gauntlet_Zerg",
	[":gazloweangry:"] = "Gazlowe_Angry",
	[":gazlowecool:"] = "Gazlowe_Cool",
	[":gazlowehappy:"] = "Gazlowe_Happy",
	[":gazlowelove:"] = "Gazlowe_Love",
	[":gazlowemeh:"] = "Gazlowe_Meh",
	[":gazloweoops:"] = "Gazlowe_Oops",
	[":gazlowerofl:"] = "Gazlowe_ROFL",
	[":gazlowesad:"] = "Gazlowe_Sad",
	[":gazlowesilly:"] = "Gazlowe_Silly",
	[":gazlowewow:"] = "Gazlowe_Surprised",
	[":gg:"] = "Good_Game",
	[":gj:"] = "Good_Job",
	[":glhf:"] = "Good_Luck_Have_Fun",
	[":gravestone:"] = "Gravestone",
	[":greymaneangry:"] = "Greymane_Angry",
	[":greymanecool:"] = "Greymane_Cool",
	[":greymanehappy:"] = "Greymane_Happy",
	[":greymanelove:"] = "Greymane_Love",
	[":greymanemeh:"] = "Greymane_Meh",
	[":greymaneoops:"] = "Greymane_Oops",
	[":greymanerofl:"] = "Greymane_ROFL",
	[":greymanesad:"] = "Greymane_Sad",
	[":greymanesilly:"] = "Greymane_Silly",
	[":greymanewow:"] = "Greymane_Surprised",
	[":guldanangry:"] = "Guldan_Angry",
	[":guldancool:"] = "Guldan_Cool",
	[":guldanhappy:"] = "Guldan_Happy",
	[":guldanlove:"] = "Guldan_Love",
	[":guldanmeh:"] = "Guldan_Meh",
	[":guldanoops:"] = "Guldan_Oops",
	[":guldanrofl:"] = "Guldan_ROFL",
	[":guldansad:"] = "Guldan_Sad",
	[":guldansilly:"] = "Guldan_Silly",
	[":guldanwow:"] = "Guldan_Surprised",
	[":ham:"] = "HAM",
	[":hangloose:"] = "Hang_Loose",
	[":tauren:"] = "Hang_Tauren",
	[":happy:"] = "Happy",
	[":illidanangry:"] = "Illidan_Angry",
	[":illidancool:"] = "Illidan_Cool",
	[":illidanhappy:"] = "Illidan_Happy",
	[":illidanlove:"] = "Illidan_Love",
	[":illidanmeh:"] = "Illidan_Meh",
	[":illidanoops:"] = "Illidan_Oops",
	[":illidanrofl:"] = "Illidan_ROFL",
	[":illidansad:"] = "Illidan_Sad",
	[":illidansilly:"] = "Illidan_Silly",
	[":illidanwow:"] = "Illidan_Surprised",
	[":jainaangry:"] = "Jaina_Angry",
	[":jainacool:"] = "Jaina_Cool",
	[":jainahappy:"] = "Jaina_Happy",
	[":jainalove:"] = "Jaina_Love",
	[":jainameh:"] = "Jaina_Meh",
	[":jainaoops:"] = "Jaina_Oops",
	[":jainarofl:"] = "Jaina_ROFL",
	[":jainasad:"] = "Jaina_Sad",
	[":jainasilly:"] = "Jaina_Silly",
	[":jainawow:"] = "Jaina_Surprised",
	[":kaelthasangry:"] = "Kaelthas_Angry",
	[":kaelthascool:"] = "Kaelthas_Cool",
	[":kaelthashappy:"] = "Kaelthas_Happy",
	[":kaelthaslove:"] = "Kaelthas_Love",
	[":kaelthasmeh:"] = "Kaelthas_Meh",
	[":kaelthasoops:"] = "Kaelthas_Oops",
	[":kaelthasrofl:"] = "Kaelthas_ROFL",
	[":kaelthassad:"] = "Kaelthas_Sad",
	[":kaelthassilly:"] = "Kaelthas_Silly",
	[":kaelthaswow:"] = "Kaelthas_Surprised",
	[":rockon:"] = "Keep_Rockin",
	[":liliangry:"] = "LiLi_Angry",
	[":lilicool:"] = "LiLi_Cool",
	[":lilihappy:"] = "LiLi_Happy",
	[":lililove:"] = "LiLi_Love",
	[":lilimeh:"] = "LiLi_Meh",
	[":lilioops:"] = "LiLi_Oops",
	[":lilirofl:"] = "LiLi_ROFL",
	[":lilisad:"] = "LiLi_Sad",
	[":lilisilly:"] = "LiLi_Silly",
	[":liliwow:"] = "LiLi_Surprised",
	[":limingangry:"] = "LiMing_Angry",
	[":limingcool:"] = "LiMing_Cool",
	[":liminghappy:"] = "LiMing_Happy",
	[":liminglove:"] = "LiMing_Love",
	[":limingmeh:"] = "LiMing_Meh",
	[":limingoops:"] = "LiMing_Oops",
	[":limingrofl:"] = "LiMing_ROFL",
	[":limingsad:"] = "LiMing_Sad",
	[":limingsilly:"] = "LiMing_Silly",
	[":limingwow:"] = "LiMing_Surprised",
	[":love:"] = "Love",
	[":lunaraangry:"] = "Lunara_Angry",
	[":lunaracool:"] = "Lunara_Cool",
	[":lunarahappy:"] = "Lunara_Happy",
	[":lunaralove:"] = "Lunara_Love",
	[":lunarameh:"] = "Lunara_Meh",
	[":lunaraoops:"] = "Lunara_Oops",
	[":lunararofl:"] = "Lunara_ROFL",
	[":lunarasad:"] = "Lunara_Sad",
	[":lunarasilly:"] = "Lunara_Silly",
	[":lunarawow:"] = "Lunara_Surprised",
	[":malfurionangry:"] = "Malfurion_Angry",
	[":malfurioncool:"] = "Malfurion_Cool",
	[":malfurionhappy:"] = "Malfurion_Happy",
	[":malfurionlove:"] = "Malfurion_Love",
	[":malfurionmeh:"] = "Malfurion_Meh",
	[":malfurionoops:"] = "Malfurion_Oops",
	[":malfurionrofl:"] = "Malfurion_ROFL",
	[":malfurionsad:"] = "Malfurion_Sad",
	[":malfurionsilly:"] = "Malfurion_Silly",
	[":malfurionwow:"] = "Malfurion_Surprised",
	[":medivhangry:"] = "Medivh_Angry",
	[":medivhcool:"] = "Medivh_Cool",
	[":medivhhappy:"] = "Medivh_Happy",
	[":medivhlove:"] = "Medivh_Love",
	[":medivhmeh:"] = "Medivh_Meh",
	[":medivhoops:"] = "Medivh_Oops",
	[":medivhrofl:"] = "Medivh_ROFL",
	[":medivhsad:"] = "Medivh_Sad",
	[":medivhsilly:"] = "Medivh_Silly",
	[":medivhwow:"] = "Medivh_Surprised",
	[":meh:"] = "Meh",
	[":muradinangry:"] = "Muradin_Angry",
	[":muradincool:"] = "Muradin_Cool",
	[":muradinhappy:"] = "Muradin_Happy",
	[":muradinlove:"] = "Muradin_Love",
	[":muradinmeh:"] = "Muradin_Meh",
	[":muradinoops:"] = "Muradin_Oops",
	[":muradinrofl:"] = "Muradin_ROFL",
	[":muradinsad:"] = "Muradin_Sad",
	[":muradinsilly:"] = "Muradin_Silly",
	[":muradinwow:"] = "Muradin_Surprised",
	[":murkyangry:"] = "Murky_Angry",
	[":murkycool:"] = "Murky_Cool",
	[":murkyhappy:"] = "Murky_Happy",
	[":murkylove:"] = "Murky_Love",
	[":murkymeh:"] = "Murky_Meh",
	[":murkyoops:"] = "Murky_Oops",
	[":murkyrofl:"] = "Murky_ROFL",
	[":murkysad:"] = "Murky_Sad",
	[":murkysilly:"] = "Murky_Silly",
	[":murkywow:"] = "Murky_Surprised",
	[":oops:"] = "Oops",
	[":oclap:"] = "OrcApplause",
	[":ofingerx:"] = "OrcFingers_Crossed",
	[":ofistbump:"] = "OrcFingers_Pound_It",
	[":oflex:"] = "OrcFlex",
	[":ohangloose:"] = "OrcHang_Loose",
	[":orockon:"] = "OrcKeep_Rockin",
	[":opaper:"] = "OrcPaper",
	[":opoint:"] = "OrcPoint",
	[":orock:"] = "OrcRock",
	[":oscissors:"] = "OrcScissors",
	[":ohandshake:"] = "OrcShake",
	[":otauren:"] = "OrcTauren",
	[":on:"] = "OrcThumbs_Down",
	[":oy:"] = "OrcThumbs_Up",
	[":ozerg:"] = "OrcZerg",
	[":paper:"] = "Paper",
	[":popper:"] = "Party_Popper",
	[":fw:"] = "Pew_Pew",
	[":party:"] = "PFFFTHRRRRT",
	[":point:"] = "Point",
	[":popcorn:"] = "Popcorn",
	[":potato:"] = "Potato",
	[":fistbump:"] = "Pound_It",
	[":present:"] = "Present",
	[":ragnarosangry:"] = "Ragnaros_Angry",
	[":ragnaroscool:"] = "Ragnaros_Cool",
	[":ragnaroshappy:"] = "Ragnaros_Happy",
	[":ragnaroslove:"] = "Ragnaros_Love",
	[":ragnarosmeh:"] = "Ragnaros_Meh",
	[":ragnarosoops:"] = "Ragnaros_Oops",
	[":ragnarosrofl:"] = "Ragnaros_ROFL",
	[":ragnarossad:"] = "Ragnaros_Sad",
	[":ragnarossilly:"] = "Ragnaros_Silly",
	[":ragnaroswow:"] = "Ragnaros_Surprised",
	[":rehgarangry:"] = "Rehgar_Angry",
	[":rehgarcool:"] = "Rehgar_Cool",
	[":rehgarhappy:"] = "Rehgar_Happy",
	[":rehgarlove:"] = "Rehgar_Love",
	[":rehgarmeh:"] = "Rehgar_Meh",
	[":rehgaroops:"] = "Rehgar_Oops",
	[":rehgarrofl:"] = "Rehgar_ROFL",
	[":rehgarsad:"] = "Rehgar_Sad",
	[":rehgarsilly:"] = "Rehgar_Silly",
	[":rehgarwow:"] = "Rehgar_Surprised",
	[":rexxarangry:"] = "Rexxar_Angry",
	[":rexxarcool:"] = "Rexxar_Cool",
	[":rexxarhappy:"] = "Rexxar_Happy",
	[":rexxarlove:"] = "Rexxar_Love",
	[":rexxarmeh:"] = "Rexxar_Meh",
	[":rexxaroops:"] = "Rexxar_Oops",
	[":rexxarrofl:"] = "Rexxar_ROFL",
	[":rexxarsad:"] = "Rexxar_Sad",
	[":rexxarsilly:"] = "Rexxar_Silly",
	[":rexxarwow:"] = "Rexxar_Surprised",
	[":riceball:"] = "Riceball",
	[":rip:"] = "RIP_friend",
	[":rock:"] = "Rock",
	[":rofl:"] = "Rofl",
	[":sad:"] = "Sad",
	[":salt:"] = "Salt",
	[":samuroangry:"] = "Samuro_Angry",
	[":samurocool:"] = "Samuro_Cool",
	[":samurohappy:"] = "Samuro_Happy",
	[":samurolove:"] = "Samuro_Love",
	[":samuromeh:"] = "Samuro_Meh",
	[":samurooops:"] = "Samuro_Oops",
	[":samurorofl:"] = "Samuro_ROFL",
	[":samurosad:"] = "Samuro_Sad",
	[":samurosilly:"] = "Samuro_Silly",
	[":samurowow:"] = "Samuro_Surprised",
	[":scissors:"] = "Scissors",
	[":handshake:"] = "Shake",
	[":silly:"] = "Silly",
	[":bones:"] = "Skull_and_Crossbones",
	[":zzz:"] = "Sleepy",
	[":tofu:"] = "Stinky_Block_of_Tofu",
	[":stitchesangry:"] = "Stitches_Angry",
	[":stitchescool:"] = "Stitches_Cool",
	[":stitcheshappy:"] = "Stitches_Happy",
	[":stitcheslove:"] = "Stitches_Love",
	[":stitchesmeh:"] = "Stitches_Meh",
	[":stitchesoops:"] = "Stitches_Oops",
	[":stitchesrofl:"] = "Stitches_ROFL",
	[":stitchessad:"] = "Stitches_Sad",
	[":stitchessilly:"] = "Stitches_Silly",
	[":stitcheswow:"] = "Stitches_Surprised",
	[":wow:"] = "Surprised",
	[":sushi:"] = "Sushi",
	[":stt:"] = "Sweet_Cry",
	[":sgg:"] = "Sweet_Good_Game",
	[":sgj:"] = "Sweet_Good_Job",
	[":sglhf:"] = "Sweet_Good_Luck_Have_Fun",
	[":szzz:"] = "Sweet_Sleepy",
	[":sylvanasangry:"] = "Sylvanas_Angry",
	[":sylvanascool:"] = "Sylvanas_Cool",
	[":sylvanashappy:"] = "Sylvanas_Happy",
	[":sylvanaslove:"] = "Sylvanas_Love",
	[":sylvanasmeh:"] = "Sylvanas_Meh",
	[":sylvanasoops:"] = "Sylvanas_Oops",
	[":sylvanasrofl:"] = "Sylvanas_ROFL",
	[":sylvanassad:"] = "Sylvanas_Sad",
	[":sylvanassilly:"] = "Sylvanas_Silly",
	[":sylvanaswow:"] = "Sylvanas_Surprised",
	[":thrallangry:"] = "Thrall_Angry",
	[":thrallcool:"] = "Thrall_Cool",
	[":thrallhappy:"] = "Thrall_Happy",
	[":thralllove:"] = "Thrall_Love",
	[":thrallmeh:"] = "Thrall_Meh",
	[":thralloops:"] = "Thrall_Oops",
	[":thrallrofl:"] = "Thrall_ROFL",
	[":thrallsad:"] = "Thrall_Sad",
	[":thrallsilly:"] = "Thrall_Silly",
	[":thrallwow:"] = "Thrall_Surprised",
	[":n:"] = "Thumbs_Down",
	[":y:"] = "Thumbs_Up",
	[":tyrandeangry:"] = "Tyrande_Angry",
	[":tyrandecool:"] = "Tyrande_Cool",
	[":tyrandehappy:"] = "Tyrande_Happy",
	[":tyrandelove:"] = "Tyrande_Love",
	[":tyrandemeh:"] = "Tyrande_Meh",
	[":tyrandeoops:"] = "Tyrande_Oops",
	[":tyranderofl:"] = "Tyrande_ROFL",
	[":tyrandesad:"] = "Tyrande_Sad",
	[":tyrandesilly:"] = "Tyrande_Silly",
	[":tyrandewow:"] = "Tyrande_Surprised",
	[":murkshimi:"] = "Uhh",
	[":utherangry:"] = "Uther_Angry",
	[":uthercool:"] = "Uther_Cool",
	[":utherhappy:"] = "Uther_Happy",
	[":utherlove:"] = "Uther_Love",
	[":uthermeh:"] = "Uther_Meh",
	[":utheroops:"] = "Uther_Oops",
	[":utherrofl:"] = "Uther_ROFL",
	[":uthersad:"] = "Uther_Sad",
	[":uthersilly:"] = "Uther_Silly",
	[":utherwow:"] = "Uther_Surprised",
	[":valeeraangry:"] = "Valeera_Angry",
	[":valeeracool:"] = "Valeera_Cool",
	[":valeerahappy:"] = "Valeera_Happy",
	[":valeeralove:"] = "Valeera_Love",
	[":valeerameh:"] = "Valeera_Meh",
	[":valeeraoops:"] = "Valeera_Oops",
	[":valeerarofl:"] = "Valeera_ROFL",
	[":valeerasad:"] = "Valeera_Sad",
	[":valeerasilly:"] = "Valeera_Silly",
	[":valeerawow:"] = "Valeera_Surprised",
	[":varianangry:"] = "Varian_Angry",
	[":variancool:"] = "Varian_Cool",
	[":varianhappy:"] = "Varian_Happy",
	[":varianlove:"] = "Varian_Love",
	[":varianmeh:"] = "Varian_Meh",
	[":varianoops:"] = "Varian_Oops",
	[":varianrofl:"] = "Varian_ROFL",
	[":variansad:"] = "Varian_Sad",
	[":variansilly:"] = "Varian_Silly",
	[":varianwow:"] = "Varian_Surprised",
	[":zerg:"] = "Zerg",
	[":zuljinangry:"] = "Zuljin_Angry",
	[":zuljincool:"] = "Zuljin_Cool",
	[":zuljinhappy:"] = "Zuljin_Happy",
	[":zuljinlove:"] = "Zuljin_Love",
	[":zuljinmeh:"] = "Zuljin_Meh",
	[":zuljinoops:"] = "Zuljin_Oops",
	[":zuljinrofl:"] = "Zuljin_ROFL",
	[":zuljinsad:"] = "Zuljin_Sad",
	[":zuljinsilly:"] = "Zuljin_Silly",
	[":zuljinwow:"] = "Zuljin_Surprised",
}

local function startsWith(str, start)
    return str:sub(1, #start) == start;
end

local function oneStartsWith(str, start)
	if startsWith(str, start) then
		return true;
	end

    return false;
end

local function GetMatches(text, numResults)
    local results = {};

	for shortCode, emoji in pairs(Me.EmojiList) do
		if oneStartsWith(shortCode, text) then
			table.insert(
				results,
				{
					["name"]     = "|TInterface/AddOns/DiceMaster/Texture/Emoji/"..emoji..":0:0:0:0:64:64:16:48:16:48|t "..shortCode,
					["priority"] = LE_AUTOCOMPLETE_PRIORITY_OTHER
				}
			);
		end

		if #results >= numResults then
			return results;
		end
	end

    return results;
end

local function Autocomplete(editBox, _, nameInfo)
	local complete = nameInfo.name:match(Emoji_CompleteRegex .. "$");
	local cursorPosition = editBox:GetCursorPosition();
    local text = editBox:GetText();
    local beginning = text:sub(1, cursorPosition);
    local incomplete = beginning:match(Emoji_IncompleteRegex);
	
    if complete or incomplete then
        if incomplete then
            local newText = beginning:sub(1, -(#incomplete) - 1) .. complete .. ' ';
            editBox:SetText(newText .. text:sub(cursorPosition + 1));
            editBox:SetCursorPosition(#newText);
        end

        return true;
    end

    return false;
end

function Me.Emoji_OnTextChanged(self, userInput)
	if not ( userInput ) then
		return
	end
	
	if not ( Me.db.global.enableEmojis ) then
		return
	end
	
	local text = self:GetText();
    local beginning = text:sub(1, self:GetCursorPosition());
    local shortCode = beginning:match(Emoji_IncompleteRegex);
	
	if shortCode then
		AutoCompleteEditBox_SetAutoCompleteSource(self, GetMatches);
        AutoCompleteEditBox_SetCustomAutoCompleteFunction(self, Autocomplete);
        AutoComplete_Update(self, shortCode, #shortCode);
	end
end

function Me.Emoji_OnChatMessage(self, event, message, sender, ...)
	local found_links = false;
	local emojiSize = 14;
	
	if _G.SELECTED_DOCK_FRAME then
		emojiSize = select(2, _G.SELECTED_DOCK_FRAME:GetFont())
	end
	
	local clean = string.gsub(message, Emoji_CompleteRegex, function(shortCode)
		local texture = Me.EmojiList[shortCode];
		if texture then
			return "|TInterface/AddOns/DiceMaster/Texture/Emoji/"..texture..":"..emojiSize..":"..emojiSize..":0:0:64:64:16:48:16:48|t ";
		else
			return shortCode
		end
	end);

	return false, clean, sender, ...;
end

function Me.Emoji_Init()
	for i = 1, NUM_CHAT_WINDOWS do
        local editbox = _G["ChatFrame" .. i .. "EditBox"];
        if editbox then
            editbox:SetScript("OnTextChanged", Me.Emoji_OnTextChanged);
            editbox.HasStickyFocus = function() return true; end
        end
    end

    for _, t in pairs(CHAT_MSG_TYPES) do
       ChatFrame_AddMessageEventFilter("CHAT_MSG_" .. t, Me.Emoji_OnChatMessage);
    end
	
	hooksecurefunc('ChatEdit_UpdateHeader', function(editBox)
        local chatType = editBox:GetAttribute('chatType');
        if not chatType then
            return;
        end

        local header = _G[editBox:GetName()..'Header'];
        local headerSuffix = _G[editBox:GetName()..'HeaderSuffix'];

        if not header then
            return;
        end

        editBox:SetTextInsets(15 + header:GetWidth() + (headerSuffix:IsShown() and headerSuffix:GetWidth() or 0), 13 + 20, 0, 0);
    end);
end
