extends RefCounted
class_name GameMetadata

const GAME_NAME := "Okçuların Son Kalesi"
const SHORT_DESCRIPTION := (
	"Okçuların Son Kalesi, düşman dalgalarına karşı kuleler kurduğun, "
	+ "kulelerini geliştirdiğin ve son kaleyi savunduğun bir kule savunması oyunudur."
)
const PURPOSE := (
	"Amacın kıvrımlı yolu aşmaya çalışan düşmanları durdurmak ve son kaleyi "
	+ "olabildiğince sağlam tutmaktır."
)
const ENGINE := "Godot"
const DEVELOPER := "[Geliştirici adı]"
const VERSION := "1.0.0-rc"
const COPYRIGHT := "© [Yıl] [Hak sahibi]"
const LICENSE := "[Lisans bilgisi]"


static func get_about_text() -> String:
	return (
		"%s\n\n%s\n\nOyunun amacı\n%s\n\n"
		+ "Oyun motoru: %s\nGeliştirici: %s\nSürüm: %s\n%s\nLisans: %s"
	) % [
		GAME_NAME,
		SHORT_DESCRIPTION,
		PURPOSE,
		ENGINE,
		DEVELOPER,
		VERSION,
		COPYRIGHT,
		LICENSE
	]
