extends Node3D

func update_chase_music():
	var enemies = get_tree().get_nodes_in_group("enemy")
	var someone_is_chasing = false
	
	for e in enemies:
		if e.state == e.EnemyState.CHASING:
			someone_is_chasing = true
			break
	
	if someone_is_chasing:
		if not $Musics/ChaseMusic.playing:
			$Musics/ChaseMusic.play()
		if $Musics/MapMusic.playing:
			$Musics/MapMusic.stop()
	else:
		if $Musics/ChaseMusic.playing:
			$Musics/ChaseMusic.stop()
		if not $Musics/MapMusic.playing:
			$Musics/MapMusic.play()
