import Foundation

// Modes of connection: used by descriptor_data.state
enum DescriptorState {
    case getCharset             // Charset?
    case getAccountName         // Account name or 'start'
    case accountPassword        // Password:
    case confirmAccountCreation // Create account?
    case verifyConfirmationCode //
    case newPassword            // Give me a password for x
    case confirmPassword        // Please retype password:
    
    case getNameReal            // Регистрация нового персонажа
    case nameConfirmation       // Did I get that right, x?
    case qSex                   // Sex?
    case getNameGenitive        // By what name ..? род
    case getNameDative          // By what name ..? дат
    case getNameAccusative      // By what name ..? вин
    case getNameInstrumental    // By what name ..? твр
    case getNamePrepositional   // By what name ..? пре
    case qClass                 // Class?
    case qRace                  // Race?
    case qAlignment             // Alignment?
    case loadRoom               // Стартовый город (vnum комнаты входа)
    case creatureCreationCompleted  // Конец регистрации
    
    case accountMenu
    case chooseCreature
    case changeAccountPasswordGetOld
    case changeAccountPasswordGetNew
    case changeAccountPasswordConfirm
    case deleteAccountConfirmation1
    case deleteAccountConfirmation2
    
    case creatureMenu
    case exDescription          // Enter a new description:
    case deleteCreatureConfirmation1
    case deleteCreatureConfirmation2
    
    //case rmotd                  // PRESS RETURN after MOTD

    case ban                    // Disconnect after any input
    case close                  // Disconnecting
    
    case playing                // Playing - Nominal state
}
