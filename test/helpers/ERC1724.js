const { note } = require('aztec.js');
const secp256k1 = require('@aztec/secp256k1');

const userA = secp256k1.generateAccount();
const userB = secp256k1.generateAccount();

/**
 * Generate a set of notes, given the desired note values and account of the owner
 *
 * @method getNotesForAccount
 * @param {Object} aztecAccount - Ethereum account that owns the notes to be created
 * @param {Number[]} noteValues - array of note values, for which notes will be created
 * @returns {Note[]} - array of notes
 */
const getNotesForAccount = async (aztecAccount, noteValues) => {
    return Promise.all(noteValues.map((noteValue) => note.create(aztecAccount.publicKey, noteValue)));
};

/**
 * General purpose function that generates a set of notes to be used in a deposit join split proof.
 *
 * There are no inputNotes created in this function - it generates notes for a deposit proof i.e. a joinSplit
 * where tokens are being converted into notes.
 *
 * Output notes are created. The values of these output notes is determined by the input argument
 * depositOutputNoteValues
 *
 * @method getDepositNotes
 * @param {Number[]} depositOutputNoteValues - array of note values, for which notes will be created
 * @returns {Note[]} depositInputNotes - input notes for a deposit join split proof
 * @returns {Note[]} depositOutputNotes - output notes for a deposit join split proof
 * @returns {Object[]} depositInputOwnerAccounts - Ethereum accounts of the input note owners
 * @returns {Object[]} depositOutputOwnerAccounts - Ethereum accounts of the output note owners
 */
const getDepositNotes = async (depositOutputNoteValues) => {
    const depositInputNotes = [];
    const depositOutputNotes = await getNotesForAccount(userA, depositOutputNoteValues);
    const depositInputOwnerAccounts = [];
    const depositOutputOwnerAccounts = [userA];
    return {
        depositInputNotes,
        depositOutputNotes,
        depositInputOwnerAccounts,
        depositOutputOwnerAccounts,
    };
};

/**
 * Generates a default set of notes to be used in a deposit proof - a joinSplit proof that converts tokens
 * into output notes
 *
 * Default notes and values are:
 * - no input notes
 * - depositPublicValue = 10
 * - one output note, value = 10
 *
 * @method getDefaultDepositNotes
 * @returns {Object} ...notes - outputs from the getDepositNotes() function
 * @returns {Numbner} depositPublicValue - number of tokens being converted into notes
 */
const getDefaultDepositNotes = async () => {
    // There is no input note, as value is being deposited into ACE with an output
    // note being created
    const outputNoteValues = [10];
    const depositPublicValue = 10;

    const notes = await getDepositNotes(outputNoteValues);
    return {
        ...notes,
        depositPublicValue,
    };
};

module.exports = {
    getDepositNotes,
    getDefaultDepositNotes,
    getNotesForAccount
}