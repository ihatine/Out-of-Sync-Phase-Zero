extends Interactable
class_name TestInteractableObject

@export_multiline var interaction_message: String = "Объект не отвечает."

func interact(_player: Node) -> void:
    print(interaction_message)
