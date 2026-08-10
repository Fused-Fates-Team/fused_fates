#================================================================================================
# Pokémon Fused Fates Wonder Link System - 003_Trainer.rb
#================================================================================================
require 'zlib'

#==================================================================
# module WonderLinkTrainer
#==================================================================
module WonderLinkTrainer
  # Constructs and returns a trainer dynamically using the decoder
  def self.create_trainer_from_code(code, trainer_name = "Wonder Rival")
    if code.nil? || code.empty?
      pbMessage(_INTL("Invalid or empty Wonder Link code!"))
      return nil
    end

    # Delegate party array extraction to WonderLinkDecoder
    decoded_data = WonderLinkDecoder.decode_party_array(code)

    if decoded_data.nil? || decoded_data[:party].nil? || decoded_data[:party].empty?
      pbMessage(_INTL("The Wonder Link code contained no valid Pokémon."))
      return nil
    end

    party = decoded_data[:party]

    # Assign the decoded party owner's name
    trainer_name = decoded_data[:owner]
    trainer_name = fallback_name if trainer_name.nil? || trainer_name.strip.empty?

    trainer_type = :RIVAL1

    # Construct and return the dynamic enemy trainer object
    enemy_trainer = NPCTrainer.new(trainer_name, trainer_type, 0)
    enemy_trainer.party = party

    return enemy_trainer
  end

  # Immediately initiate a trainer battle using the clipboard code
  def self.start_battle_from_clipboard(fallback_name = "Wonder Rival")
    code = Input.clipboard
    trainer = create_trainer_from_code(code, fallback_name)
    return false unless trainer

    TrainerBattle.start(trainer)
    return true
  end
end