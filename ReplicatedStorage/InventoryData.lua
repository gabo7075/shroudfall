-- ModuleScript: ReplicatedStorage > InventoryData
local InventoryData = {}

-- ===============================================
-- USUARIOS CON ACCESO A CONTENIDO EXCLUSIVO
-- ===============================================

InventoryData.AllowedUsernames = {
	"extermillon09",  -- Reemplaza con nombres de usuarios reales
	"Player1",
	"Player3",
	-- Agrega más nombres aquí
}

-- Función para verificar si un usuario tiene acceso a contenido exclusivo
function InventoryData:HasExclusiveAccess(username)
	for _, name in ipairs(self.AllowedUsernames) do
		if name == username then
			return true
		end
	end
	return false
end

-- ===============================================
-- CATEGORÍAS Y PERSONAJES
-- ===============================================

-- 9762988755 < -- este id es para imagen placeholder

InventoryData.Categories = {
	{
		Name = "Killers",
		DisplayName = "Killers",
		ImageId = "rbxassetid://107888632746988",
		Price = 1,
		Items = {
			{
				Name = "KillerTemplate",
				DisplayName = "Killer Template",
				ImageId = "rbxassetid://9762988755",
				Price = 9999,
				Exclusive = true,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://9762988755",
						Price = 1,
						Exclusive = false
					}
				}
			},
			{
				Name = "Zombie",
				DisplayName = "Zombie",
				ImageId = "rbxassetid://101873701815779",
				Price = 1,
				Exclusive = false, -- Personaje normal
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://101873701815779",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Area 51",
						DisplayName = "Area 51",
						ImageId = "rbxassetid://114194539551236",
						Price = 1000,
						Exclusive = false
					},
					{
						Name = "Bloody",
						DisplayName = "Bloody",
						ImageId = "rbxassetid://138090399272771",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Botanophobia",
						DisplayName = "Botanophobia",
						ImageId = "rbxassetid://134200362157275",
						Price = 1209,
						Exclusive = false
					},
					{
						Name = "Classic",
						DisplayName = "Classic",
						ImageId = "rbxassetid://92521362582047",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Drowned",
						DisplayName = "Drowned",
						ImageId = "rbxassetid://110816186110291",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Ebon",
						DisplayName = "Ebon",
						ImageId = "rbxassetid://9762988755",
						Price = 750,
						Exclusive = false
					},
					{
						Name = "Emo",
						DisplayName = "Emo",
						ImageId = "rbxassetid://81810689361709",
						Price = 325,
						Exclusive = false
					},
					{
						Name = "Ghostly",
						DisplayName = "Ghostly",
						ImageId = "rbxassetid://100527236566706",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Infected",
						DisplayName = "Infected",
						ImageId = "rbxassetid://81593962870402",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Scorched",
						DisplayName = "Scorched",
						ImageId = "rbxassetid://120845990441796",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Police",
						DisplayName = "Police",
						ImageId = "rbxassetid://9762988755",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Skeleton",
						DisplayName = "Skeleton",
						ImageId = "rbxassetid://9762988755",
						Price = 600,
						Exclusive = false
					},
					{
						Name = "Elf",
						DisplayName = "Elf",
						ImageId = "rbxassetid://9762988755",
						Price = 400,
						Exclusive = false
					}
				}
			},
			{
				Name = "Alien",
				DisplayName = "Alien",
				ImageId = "rbxassetid://113644109566620",
				Price = 1,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://113644109566620",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Red",
						DisplayName = "Red",
						ImageId = "rbxassetid://9762988755",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Purple",
						DisplayName = "Purple",
						ImageId = "rbxassetid://9762988755",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Guard",
						DisplayName = "Guard",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Retro",
						DisplayName = "Retro",
						ImageId = "rbxassetid://85340728226268",
						Price = 500,
						Exclusive = false
					}
				}
			},
			{
				Name = "Anti Burras",
				DisplayName = "Anti Burras",
				ImageId = "rbxassetid://105257366931537",
				Price = 1150,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://105257366931537",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "pasar13",
						DisplayName = "pasar13",
						ImageId = "rbxassetid://9762988755",
						Price = 10,
						Exclusive = true
					},
					{
						Name = "Boon",
						DisplayName = "Boon",
						ImageId = "rbxassetid://119115360567345",
						Price = 600,
						Exclusive = false
					},
					{
						Name = "Couple",
						DisplayName = "Couple",
						ImageId = "rbxassetid://109556784583085",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Emerald",
						DisplayName = "Emerald",
						ImageId = "rbxassetid://109245604992568",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Executioner",
						DisplayName = "Executioner",
						ImageId = "rbxassetid://104554357810379",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Formal",
						DisplayName = "Formal",
						ImageId = "rbxassetid://132668419893106",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Low Budget",
						DisplayName = "Low Budget",
						ImageId = "rbxassetid://129936498145572",
						Price = 250,
						Exclusive = false
					},
					{
						Name = "Tourist",
						DisplayName = "Tourist",
						ImageId = "rbxassetid://77714822567927",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Santa",
						DisplayName = "Santa",
						ImageId = "rbxassetid://9762988755",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Tseug",
						DisplayName = "Tseug",
						ImageId = "rbxassetid://126848049275084",
						Price = 666,
						Exclusive = false
					},
					{
						Name = "Riah Nocab",
						DisplayName = "Riah Nocab",
						ImageId = "rbxassetid://99627784673640",
						Price = 600,
						Exclusive = false
					},
					{
						Name = "c00l",
						DisplayName = "c00l",
						ImageId = "rbxassetid://126796426948419",
						Price = 1000,
						Exclusive = false
					}
				}
			},
			{
				Name = "Jeff The Killer",
				DisplayName = "Jeff The Killer",
				ImageId = "rbxassetid://107390919074700",
				Price = 950,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://107390919074700",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Butcher",
						DisplayName = "Butcher",
						ImageId = "rbxassetid://90418145655537",
						Price = 350,
						Exclusive = false
					},
					{
						Name = "Clown",
						DisplayName = "Clown",
						ImageId = "rbxassetid://88770050768900",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Formal",
						DisplayName = "Formal",
						ImageId = "rbxassetid://113240550101769",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Toolbox",
						DisplayName = "Toolbox",
						ImageId = "rbxassetid://84804803361176",
						Price = 250,
						Exclusive = false
					},
					{
						Name = "Festive Killer",
						DisplayName = "Festive Killer",
						ImageId = "rbxassetid://9762988755",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Follower",
						DisplayName = "Follower",
						ImageId = "rbxassetid://103267205731141",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Pre-Ordeal",
						DisplayName = "Pre-Ordeal",
						ImageId = "rbxassetid://83264368227662",
						Price = 350,
						Exclusive = false
					},
					{
						Name = "2010",
						DisplayName = "2010",
						ImageId = "rbxassetid://121815560359245",
						Price = 700,
						Exclusive = false
					},
					{
						Name = "Eyeless Jack",
						DisplayName = "Eyeless Jack",
						ImageId = "rbxassetid://119087972846997",
						Price = 800,
						Exclusive = false
					}
				}
			},
			{
				Name = "Zorath",
				DisplayName = "Zorath",
				ImageId = "rbxassetid://108130105095024",
				Price = 1450,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://108130105095024",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Breakout",
						DisplayName = "Breakout",
						ImageId = "rbxassetid://137743921137586",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Corrupted",
						DisplayName = "Corrupted",
						ImageId = "rbxassetid://137908627771002",
						Price = 150,
						Exclusive = false
					},
					{
						Name = "Dignity",
						DisplayName = "Dignity",
						ImageId = "rbxassetid://139685177690538",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Military",
						DisplayName = "Military",
						ImageId = "rbxassetid://95253436746607",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Patient",
						DisplayName = "Patient",
						ImageId = "rbxassetid://124142748882944",
						Price = 250,
						Exclusive = false
					},
					{
						Name = "Toolbox",
						DisplayName = "Toolbox",
						ImageId = "rbxassetid://91803608887516",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Warzone",
						DisplayName = "Warzone",
						ImageId = "rbxassetid://82636327306439",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Green Virus",
						DisplayName = "Green Virus",
						ImageId = "rbxassetid://121088295906093",
						Price = 525,
						Exclusive = false
					}
				}
			},
			{
				Name = "r3ADe",
				DisplayName = "r3ADe",
				ImageId = "rbxassetid://72092325673802",
				Price = 1350,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://72092325673802",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "2017",
						DisplayName = "2017",
						ImageId = "rbxassetid://117745335385824",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Santa Robot",
						DisplayName = "Santa Robot",
						ImageId = "rbxassetid://9762988755",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Jersey",
						DisplayName = "Jersey",
						ImageId = "rbxassetid://114213115378547",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Robot Noob",
						DisplayName = "Robot Noob",
						ImageId = "rbxassetid://70719484592582",
						Price = 350,
						Exclusive = false
					},
					{
						Name = "Simple",
						DisplayName = "Simple",
						ImageId = "rbxassetid://113286513090419",
						Price = 250,
						Exclusive = false
					},
					{
						Name = "Mr Robot",
						DisplayName = "Mr. Robot",
						ImageId = "rbxassetid://107383196537469",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "N30N",
						DisplayName = "N30N",
						ImageId = "rbxassetid://117499712633093",
						Price = 350,
						Exclusive = false
					},
					{
						Name = "The Machine",
						DisplayName = "The Machine",
						ImageId = "rbxassetid://140151231997914",
						Price = 1376,
						Exclusive = false
					}
				}
			},
			{
				Name = "Bacon Killer",
				DisplayName = "Bacon Killer",
				ImageId = "rbxassetid://90803871106656",
				Price = 1000,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://90803871106656",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Pre-Ordeal",
						DisplayName = "Pre-Ordeal",
						ImageId = "rbxassetid://135601650530017",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Acorn",
						DisplayName = "Acorn",
						ImageId = "rbxassetid://79770808121698",
						Price = 350,
						Exclusive = false
					},
					{
						Name = "Elf",
						DisplayName = "Elf",
						ImageId = "rbxassetid://9762988755",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Toolbox",
						DisplayName = "Toolbox",
						ImageId = "rbxassetid://121580969244284",
						Price = 300,
						Exclusive = false
					}
				}
			},
			{
				Name = "N43",
				DisplayName = "N43",
				ImageId = "rbxassetid://117830059036740",
				Price = 1325,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://117830059036740",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Green",
						DisplayName = "Green",
						ImageId = "rbxassetid://9762988755",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Golden",
						DisplayName = "Golden",
						ImageId = "rbxassetid://9762988755",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Creator",
						DisplayName = "Creator",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Festive",
						DisplayName = "Festive",
						ImageId = "rbxassetid://9762988755",
						Price = 150,
						Exclusive = false
					},
					{
						Name = "Robot",
						DisplayName = "Robot",
						ImageId = "rbxassetid://9762988755",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "A11_B",
						DisplayName = "A11_B",
						ImageId = "rbxassetid://80468118348901",
						Price = 450,
						Exclusive = false
					},
					{
						Name = "Scrap",
						DisplayName = "Scrap",
						ImageId = "rbxassetid://115390828503127",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "gatoleandro2",
						DisplayName = "gatoleandro2",
						ImageId = "rbxassetid://121861959610793",
						Price = 620,
						Exclusive = false
					}
				}
			},
			{
				Name = "Umbrageon",
				DisplayName = "Umbrageon",
				ImageId = "rbxassetid://127151723007706",
				Price = 1100,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://127151723007706",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Original",
						DisplayName = "Original",
						ImageId = "rbxassetid://134243179422419",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Blood Ghost",
						DisplayName = "Blood Ghost",
						ImageId = "rbxassetid://9762988755",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Phantasm",
						DisplayName = "Phantasm",
						ImageId = "rbxassetid://9762988755",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Ghastly Ghoul",
						DisplayName = "Ghastly Ghoul",
						ImageId = "rbxassetid://9762988755",
						Price = 600,
						Exclusive = false
					}
				}
			},
			{
				Name = "Maskslash",
				DisplayName = "Maskslash",
				ImageId = "rbxassetid://98597712306148",
				Price = 1200,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://98597712306148",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Legacy",
						DisplayName = "Legacy",
						ImageId = "rbxassetid://98111261290105",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Shade",
						DisplayName = "Shade",
						ImageId = "rbxassetid://92796510045800",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Festive",
						DisplayName = "Festive",
						ImageId = "rbxassetid://9762988755",
						Price = 350,
						Exclusive = false
					}
				}
			},
			{
				Name = "Echokeeper",
				DisplayName = "Echokeeper",
				ImageId = "rbxassetid://120718878738207",
				Price = 1425,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://120718878738207",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Octopus",
						DisplayName = "Octopus",
						ImageId = "rbxassetid://87047314472961",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Scary",
						DisplayName = "Scary",
						ImageId = "rbxassetid://126868397521522",
						Price = 350,
						Exclusive = false
					},
					{
						Name = "Festive",
						DisplayName = "Festive",
						ImageId = "rbxassetid://9762988755",
						Price = 300,
						Exclusive = false
					}
				}
			},
			{
				Name = "1x1x1x1",
				DisplayName = "1x1x1x1",
				ImageId = "rbxassetid://90369297583218",
				Price = 1111,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://90369297583218",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Dread",
						DisplayName = "Dread",
						ImageId = "rbxassetid://101559826872266",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Messor",
						DisplayName = "Messor",
						ImageId = "rbxassetid://115187640454347",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Red Void",
						DisplayName = "Red Void",
						ImageId = "rbxassetid://73420021295694",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Content Deleted",
						DisplayName = "Content Deleted",
						ImageId = "rbxassetid://102940064142285",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "iTrapped",
						DisplayName = "iTrapped",
						ImageId = "rbxassetid://72349659698246",
						Price = 500,
						Exclusive = false
					}
				}
			},
			{
				Name = "Slenderman",
				DisplayName = "Slenderman",
				ImageId = "rbxassetid://80407702531241",
				Price = 1100,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://80407702531241",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Megonanum",
						DisplayName = "Megonanum",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Horror",
						DisplayName = "Horror",
						ImageId = "rbxassetid://9762988755",
						Price = 250,
						Exclusive = false
					}
				}
			},
			{
				Name = "Smile Dog",
				DisplayName = "Smile Dog",
				ImageId = "rbxassetid://105879776474109",
				Price = 1008,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://105879776474109",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Cool Dog",
						DisplayName = "Cool Dog",
						ImageId = "rbxassetid://9762988755",
						Price = 150,
						Exclusive = false
					},
					{
						Name = "Guard",
						DisplayName = "Guard",
						ImageId = "rbxassetid://9762988755",
						Price = 100,
						Exclusive = false
					}
				}
			},
			{
				Name = "Sonic.EXE",
				DisplayName = "Sonic.EXE",
				ImageId = "rbxassetid://116946705306106",
				Price = 1366,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://116946705306106",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Metal",
						DisplayName = "Metal",
						ImageId = "rbxassetid://9762988755",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "NoobRBXM",
						DisplayName = "Noob.RBXM",
						ImageId = "rbxassetid://9762988755",
						Price = 666,
						Exclusive = false
					}
				}
			},
			{
				Name = "The Retributor",
				DisplayName = "The Retributor",
				ImageId = "rbxassetid://128543786844780",
				Price = 1250,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://128543786844780",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Agent",
						DisplayName = "Agent",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Original",
						DisplayName = "Original",
						ImageId = "rbxassetid://9762988755",
						Price = 150,
						Exclusive = false
					},
					{
						Name = "Secret Operation",
						DisplayName = "Secret Operation",
						ImageId = "rbxassetid://9762988755",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "The Grey",
						DisplayName = "The Grey",
						ImageId = "rbxassetid://5573433764",
						Price = 300,
						Exclusive = false
					}
				}
			},
			{
				Name = "Zombie King",
				DisplayName = "Zombie King",
				ImageId = "rbxassetid://9762988755",
				Price = 1750,
				Exclusive = true,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://9762988755",
						Price = 1,
						Exclusive = false
					}
				}
			},
			{
				Name = "The Lifeform",
				DisplayName = "The Lifeform",
				ImageId = "rbxassetid://9762988755",
				Price = 1550,
				Exclusive = true,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://9762988755",
						Price = 1,
						Exclusive = false
					}
				}
			}
		}
	},
	{
		Name = "Survivors",
		DisplayName = "Survivors",
		ImageId = "rbxassetid://95783801257103",
		Price = 2,
		Items = {
			{
				Name = "SurvTemplate",
				DisplayName = "Survivor Template",
				ImageId = "rbxassetid://9762988755",
				Price = 9999,
				Exclusive = true,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://9762988755",
						Price = 1,
						Exclusive = false
					}
				}
			},
			{
				Name = "Dummy",
				DisplayName = "Dummy",
				ImageId = "rbxassetid://115433714044280",
				Price = 1,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://115433714044280",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "BaW",
						DisplayName = "Black & White",
						ImageId = "rbxassetid://109560879221630",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "BlueTeammate",
						DisplayName = "Blue Teammate",
						ImageId = "rbxassetid://111452110764691",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "RedTeammate",
						DisplayName = "Red Teammate",
						ImageId = "rbxassetid://111016097852066",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Robloxian",
						DisplayName = "Robloxian",
						ImageId = "rbxassetid://122073573686065",
						Price = 150,
						Exclusive = false
					},
					{
						Name = "Modern",
						DisplayName = "Modern",
						ImageId = "rbxassetid://88364252904918",
						Price = 250,
						Exclusive = false
					},
					{
						Name = "Elf",
						DisplayName = "Elf",
						ImageId = "rbxassetid://122692921756357",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Classic",
						DisplayName = "Classic",
						ImageId = "rbxassetid://138470879745917",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Great Fan",
						DisplayName = "Great Fan",
						ImageId = "rbxassetid://116262224782324",
						Price = 320,
						Exclusive = false
					},
					{
						Name = "Doe",
						DisplayName = "Doe",
						ImageId = "rbxassetid://113578302923073",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Pirate",
						DisplayName = "Pirate",
						ImageId = "rbxassetid://72829193725689",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Rig",
						DisplayName = "Rig",
						ImageId = "rbxassetid://98712101259471",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Ymmud",
						DisplayName = "Ymmud",
						ImageId = "rbxassetid://74036677510957",
						Price = 550,
						Exclusive = false
					}
				}
			},
			{
				Name = "Burras",
				DisplayName = "Burras",
				ImageId = "rbxassetid://105563002277464",
				Price = 1,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://105563002277464",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Alternative",
						DisplayName = "Alternative",
						ImageId = "rbxassetid://84468893599657",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Black",
						DisplayName = "Black",
						ImageId = "rbxassetid://87685887447591",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Boxer",
						DisplayName = "Boxer",
						ImageId = "rbxassetid://136680917919038",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Couple",
						DisplayName = "Couple",
						ImageId = "rbxassetid://88844011930260",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Homeless",
						DisplayName = "Homeless",
						ImageId = "rbxassetid://76893694915933",
						Price = 150,
						Exclusive = false
					},
					{
						Name = "King",
						DisplayName = "King",
						ImageId = "rbxassetid://91192871912781",
						Price = 350,
						Exclusive = false
					},
					{
						Name = "Swag",
						DisplayName = "Swag",
						ImageId = "rbxassetid://81614196736306",
						Price = 267,
						Exclusive = false
					},
					{
						Name = "Santa",
						DisplayName = "Santa",
						ImageId = "rbxassetid://79384041848228",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Void",
						DisplayName = "Void",
						ImageId = "rbxassetid://74765754230393",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Worked Out",
						DisplayName = "Worked Out",
						ImageId = "rbxassetid://99186619023831",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Wreck",
						DisplayName = "Wreck",
						ImageId = "rbxassetid://98568889675725",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Horseface",
						DisplayName = "Horseface",
						ImageId = "rbxassetid://109330937517935",
						Price = 1000,
						Exclusive = false
					}
				}
			},
			{
				Name = "Ben",
				DisplayName = "Ben",
				ImageId = "rbxassetid://98372314898009",
				Price = 525,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://98372314898009",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Beach",
						DisplayName = "Beach",
						ImageId = "rbxassetid://130913562740049",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Citizen",
						DisplayName = "Citizen",
						ImageId = "rbxassetid://91922872820704",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Covered",
						DisplayName = "Covered",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Military",
						DisplayName = "Military",
						ImageId = "rbxassetid://136287936186084",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Robloxia",
						DisplayName = "Robloxia",
						ImageId = "rbxassetid://92219498293158",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "School",
						DisplayName = "School",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Scientist",
						DisplayName = "Scientist",
						ImageId = "rbxassetid://117839911594109",
						Price = 250,
						Exclusive = false
					},
					{
						Name = "Wizard",
						DisplayName = "Wizard",
						ImageId = "rbxassetid://113930169647728",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Winter",
						DisplayName = "Winter",
						ImageId = "rbxassetid://126318584257957",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "2017",
						DisplayName = "2017",
						ImageId = "rbxassetid://129417810582503",
						Price = 350,
						Exclusive = false
					},
					{
						Name = "Marcus",
						DisplayName = "Marcus",
						ImageId = "rbxassetid://139287788977807",
						Price = 500,
						Exclusive = false
					}
				}
			},
			{
				Name = "Recon",
				DisplayName = "Recon",
				ImageId = "rbxassetid://80623124177967",
				Price = 350,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://80623124177967",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Casual",
						DisplayName = "Casual",
						ImageId = "rbxassetid://112442321054518",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Female",
						DisplayName = "Female",
						ImageId = "rbxassetid://137409027587606",
						Price = 250,
						Exclusive = false
					},
					{
						Name = "Modern",
						DisplayName = "Modern",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Prisoner",
						DisplayName = "Prisoner",
						ImageId = "rbxassetid://108519489217600",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Professional",
						DisplayName = "Professional",
						ImageId = "rbxassetid://92258971917639",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "2x2",
						DisplayName = "2x2",
						ImageId = "rbxassetid://124998274719655",
						Price = 522,
						Exclusive = false
					}
				}
			},
			{
				Name = "Nick",
				DisplayName = "Nick",
				ImageId = "rbxassetid://80905753814998",
				Price = 350,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://80905753814998",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "80s",
						DisplayName = "80s",
						ImageId = "rbxassetid://137786259925465",
						Price = 80,
						Exclusive = false
					},
					{
						Name = "Frost",
						DisplayName = "Frost",
						ImageId = "rbxassetid://80486466569804",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Police",
						DisplayName = "Police",
						ImageId = "rbxassetid://9762988755",
						Price = 150,
						Exclusive = false
					},
					{
						Name = "Tessa",
						DisplayName = "Tessa",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Winter",
						DisplayName = "Winter",
						ImageId = "rbxassetid://140508946793208",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Inspector",
						DisplayName = "Inspector",
						ImageId = "rbxassetid://9762988755",
						Price = 583,
						Exclusive = false
					}
				}
			},
			{
				Name = "Blaze",
				DisplayName = "Blaze",
				ImageId = "rbxassetid://110235052310073",
				Price = 500,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://110235052310073",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Crimson",
						DisplayName = "Crimson",
						ImageId = "rbxassetid://132496193334013",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Winter",
						DisplayName = "Winter",
						ImageId = "rbxassetid://74023750497067",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Golden",
						DisplayName = "Golden",
						ImageId = "rbxassetid://137788018264010",
						Price = 250,
						Exclusive = false
					},
					{
						Name = "Knight",
						DisplayName = "Knight",
						ImageId = "rbxassetid://101892702572721",
						Price = 150,
						Exclusive = false
					},
					{
						Name = "Emerald",
						DisplayName = "Emerald",
						ImageId = "rbxassetid://98930726221290",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Green Elite",
						DisplayName = "Green Elite",
						ImageId = "rbxassetid://71652036039540",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Superior",
						DisplayName = "Superior",
						ImageId = "rbxassetid://117959190696329",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Swordfighter",
						DisplayName = "Swordfighter",
						ImageId = "rbxassetid://81307070261162",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Paladin",
						DisplayName = "Paladin",
						ImageId = "rbxassetid://107227177658459",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Empyrean",
						DisplayName = "Empyrean",
						ImageId = "rbxassetid://134054015028377",
						Price = 570,
						Exclusive = false
					},
					{
						Name = "Stonetroid Warrior",
						DisplayName = "Stonetroid Warrior",
						ImageId = "rbxassetid://134533334729895",
						Price = 620,
						Exclusive = false
					},
					{
						Name = "Flame General",
						DisplayName = "Flame General",
						ImageId = "rbxassetid://129033053764910",
						Price = 800,
						Exclusive = false
					}
				}
			},
			{
				Name = "CubeMan",
				DisplayName = "CubeMan",
				ImageId = "rbxassetid://96643967809585",
				Price = 575,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://96643967809585",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Actor",
						DisplayName = "Actor",
						ImageId = "rbxassetid://94672109230176",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "CubeGirl",
						DisplayName = "CubeGirl",
						ImageId = "rbxassetid://133606308490091",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Simplistic",
						DisplayName = "Simplistic",
						ImageId = "rbxassetid://84405496909272",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Tennis",
						DisplayName = "Tennis",
						ImageId = "rbxassetid://81922038743613",
						Price = 250,
						Exclusive = false
					},
					{
						Name = "Tuxedo",
						DisplayName = "Tuxedo",
						ImageId = "rbxassetid://135280945900755",
						Price = 150,
						Exclusive = false
					},
					{
						Name = "Santa",
						DisplayName = "Santa",
						ImageId = "rbxassetid://139393778902271",
						Price = 300,
						Exclusive = false
					}
				}
			},
			{
				Name = "Rae",
				DisplayName = "Rae",
				ImageId = "rbxassetid://99317022435981",
				Price = 1,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://99317022435981",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Black",
						DisplayName = "Black",
						ImageId = "rbxassetid://111267894728032",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Pajama",
						DisplayName = "Pajama",
						ImageId = "rbxassetid://95393229091748",
						Price = 250,
						Exclusive = false
					},
					{
						Name = "Social",
						DisplayName = "Social",
						ImageId = "rbxassetid://136993650492560",
						Price = 150,
						Exclusive = false
					},
					{
						Name = "Tomboy",
						DisplayName = "Tomboy",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Festive",
						DisplayName = "Festive",
						ImageId = "rbxassetid://139439064792963",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Jennifer",
						DisplayName = "Jennifer",
						ImageId = "rbxassetid://9762988755",
						Price = 600,
						Exclusive = false
					},
					{
						Name = "Noelle",
						DisplayName = "Noelle",
						ImageId = "rbxassetid://9762988755",
						Price = 575,
						Exclusive = false
					},
					{
						Name = "Jax",
						DisplayName = "Jax",
						ImageId = "rbxassetid://9762988755",
						Price = 575,
						Exclusive = false
					}
				}
			},
			{
				Name = "Leo",
				DisplayName = "Leo",
				ImageId = "rbxassetid://78630245503638",
				Price = 550,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://78630245503638",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Avatar",
						DisplayName = "Avatar",
						ImageId = "rbxassetid://109555915386944",
						Price = 150,
						Exclusive = false
					},
					{
						Name = "Early",
						DisplayName = "Early",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Orange",
						DisplayName = "Orange",
						ImageId = "rbxassetid://135028368435700",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Reindeer",
						DisplayName = "Reindeer",
						ImageId = "rbxassetid://125292716852567",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Agent",
						DisplayName = "Agent",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Diamond",
						DisplayName = "Diamond",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Police",
						DisplayName = "Police",
						ImageId = "rbxassetid://9762988755",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Lev",
						DisplayName = "Lev",
						ImageId = "rbxassetid://125971278142741",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Wither King",
						DisplayName = "Wither King",
						ImageId = "rbxassetid://9762988755",
						Price = 750,
						Exclusive = false
					}
				}
			},
			{
				Name = "Joseph",
				DisplayName = "Joseph",
				ImageId = "rbxassetid://95082835979957",
				Price = 500,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://95082835979957",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Early",
						DisplayName = "Early",
						ImageId = "rbxassetid://86433344734926",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Emo",
						DisplayName = "Emo",
						ImageId = "rbxassetid://9762988755",
						Price = 150,
						Exclusive = false
					},
					{
						Name = "Formal",
						DisplayName = "Formal",
						ImageId = "rbxassetid://110343763709577",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Neitor",
						DisplayName = "Neitor",
						ImageId = "rbxassetid://132804901804443",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "Elf",
						DisplayName = "Elf",
						ImageId = "rbxassetid://96684417602699",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Jared",
						DisplayName = "Jared",
						ImageId = "rbxassetid://139502442697560",
						Price = 500,
						Exclusive = false
					}
				}
			},
			{
				Name = "Gabo",
				DisplayName = "Gabo",
				ImageId = "rbxassetid://80111636648531",
				Price = 550,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://80111636648531",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Alternative",
						DisplayName = "Alternative",
						ImageId = "rbxassetid://140316853565766",
						Price = 150,
						Exclusive = false
					},
					{
						Name = "Baller",
						DisplayName = "Baller",
						ImageId = "rbxassetid://130171039985084",
						Price = 223,
						Exclusive = false
					},
					{
						Name = "Early",
						DisplayName = "Early",
						ImageId = "rbxassetid://119153877589839",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Emerald",
						DisplayName = "Emerald",
						ImageId = "rbxassetid://114514890850111",
						Price = 300,
						Exclusive = false
					},
					{
						Name = "In Black",
						DisplayName = "In Black",
						ImageId = "rbxassetid://96000674840089",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Military",
						DisplayName = "Military",
						ImageId = "rbxassetid://101367225890908",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Santa",
						DisplayName = "Santa",
						ImageId = "rbxassetid://116705773204019",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Masked",
						DisplayName = "Masked",
						ImageId = "rbxassetid://122975205708945",
						Price = 250,
						Exclusive = false
					},
					{
						Name = "Gale",
						DisplayName = "Gale",
						ImageId = "rbxassetid://130140065868181",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "The Hood",
						DisplayName = "The Hood",
						ImageId = "rbxassetid://130778424643059",
						Price = 500,
						Exclusive = false
					}
				}
			},
			{
				Name = "Extermillon",
				DisplayName = "Extermillon",
				ImageId = "rbxassetid://115801898245392",
				Price = 550,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://115801898245392",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Winter",
						DisplayName = "Winter",
						ImageId = "rbxassetid://121344949973380",
						Price = 250,
						Exclusive = false
					},
					{
						Name = "Bonice",
						DisplayName = "Bonice",
						ImageId = "rbxassetid://9762988755",
						Price = 350,
						Exclusive = false
					},
					{
						Name = "Classic",
						DisplayName = "Classic",
						ImageId = "rbxassetid://106756280222208",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Crafter",
						DisplayName = "Crafter",
						ImageId = "rbxassetid://75741151273862",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Joel",
						DisplayName = "Joel",
						ImageId = "rbxassetid://9762988755",
						Price = 450,
						Exclusive = false
					},
					{
						Name = "King",
						DisplayName = "King",
						ImageId = "rbxassetid://94608110148981",
						Price = 350,
						Exclusive = false
					},
					{
						Name = "Serious",
						DisplayName = "Serious",
						ImageId = "rbxassetid://98342475379973",
						Price = 450,
						Exclusive = false
					},
					{
						Name = "elqueles",
						DisplayName = "elqueles",
						ImageId = "rbxassetid://9762988755",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "elqueles2",
						DisplayName = "elqueles2",
						ImageId = "rbxassetid://9762988755",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "extermillon09",
						DisplayName = "extermillon09",
						ImageId = "rbxassetid://9762988755",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "extermillon10",
						DisplayName = "extermillon10",
						ImageId = "rbxassetid://9762988755",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "extermillon01",
						DisplayName = "extermillon01",
						ImageId = "rbxassetid://9762988755",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Marvin",
						DisplayName = "Marvin",
						ImageId = "rbxassetid://118536708411491",
						Price = 500,
						Exclusive = false
					}
				}
			},
			{
				Name = "Jehiden",
				DisplayName = "Jehiden",
				ImageId = "rbxassetid://105940388333161",
				Price = 500,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://105940388333161",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Heartbroken",
						DisplayName = "Heartbroken",
						ImageId = "rbxassetid://9762988755",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Hotline",
						DisplayName = "Hotline",
						ImageId = "rbxassetid://9762988755",
						Price = 400,
						Exclusive = false
					},
					{
						Name = "Lethal",
						DisplayName = "Lethal",
						ImageId = "rbxassetid://89919236653775",
						Price = 500,
						Exclusive = false
					},
					{
						Name = "Sans",
						DisplayName = "Sans",
						ImageId = "rbxassetid://9762988755",
						Price = 300,
						Exclusive = false
					}
				}
			},
			{
				Name = "The Inventor",
				DisplayName = "The Inventor",
				ImageId = "rbxassetid://137026848413915",
				Price = 475,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://137026848413915",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Scientist",
						DisplayName = "Scientist",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Date",
						DisplayName = "Date",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Elf",
						DisplayName = "Elf",
						ImageId = "rbxassetid://112946137578085",
						Price = 250,
						Exclusive = false
					}
				}
			},
			{
				Name = "Jkiins11",
				DisplayName = "Jkiins11",
				ImageId = "rbxassetid://133858704139356",
				Price = 450,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://133858704139356",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Red",
						DisplayName = "Red",
						ImageId = "rbxassetid://9762988755",
						Price = 100,
						Exclusive = false
					},
					{
						Name = "Leader",
						DisplayName = "Leader",
						ImageId = "rbxassetid://9762988755",
						Price = 150,
						Exclusive = false
					}
				}
			},
			{
				Name = "Synapse",
				DisplayName = "Synapse",
				ImageId = "rbxassetid://99286150703939",
				Price = 550,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://99286150703939",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "GPT",
						DisplayName = "GPT",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Perplex",
						DisplayName = "Perplex",
						ImageId = "rbxassetid://9762988755",
						Price = 200,
						Exclusive = false
					},
					{
						Name = "Festive",
						DisplayName = "Festive",
						ImageId = "rbxassetid://112139240905906",
						Price = 150,
						Exclusive = false
					}
				}
			},
			{
				Name = "Jane",
				DisplayName = "Jane",
				ImageId = "rbxassetid://101163267186565",
				Price = 500,
				Exclusive = false,
				Skins = {
					{
						Name = "Default",
						DisplayName = "Default",
						ImageId = "rbxassetid://101163267186565",
						Price = 1,
						Exclusive = false
					},
					{
						Name = "Classic",
						DisplayName = "Classic",
						ImageId = "rbxassetid://79895736400574",
						Price = 250,
						Exclusive = false
					},
					{
						Name = "Formal",
						DisplayName = "Formal",
						ImageId = "rbxassetid://76977484266585",
						Price = 150,
						Exclusive = false
					}
				}
			}
		}
	}
}

return InventoryData