module.exports.PROMPT_TYPE = {
    GENERATION: 0,
    INPAINTING: 1,
}

module.exports.ERROR_MESSAGE = {
    USER_BEING_VOTED_OUT: 'You cannot post when there is an active vote to remove you from the Circle',
}

module.exports.COIN_PAYMENT_TYPE = {
    IMAGE_GENERATION: 'Generated Image',
    PURCHASED_COINS: 'Purchased IronCoins',
    GAVE_COINS: "Gave IronCoin",
    GIFTED_COINS: "Gifted IronCoin",
    SUBSCRIBER_COINS: "Subscription IronCoin",
    REFUND_IRONCOIN: "Refunded IronCoin",
}

module.exports.NETWORK_TYPE = {
    FORGE: 0,
    HOSTED: 1,
    SELF_HOSTED: 2,
}

module.exports.NOTIFICATION_TYPE = {
    MESSAGE: 0,
    EVENT: 1,
    DELETE: 2,
    INVITATION: 3,
    ACTION_NEEDED: 4,
    DEVICE_WIPE: 5,
    DEVICE_DEACTIVATED: 6,
    //USER_REQUEST_UPDATE??
    BACKLOG_REPLY: 8,
    BACKLOG_ITEM: 9,
    GIFTED_IRONCOIN: 11,
    REPLY: 13,
    REPLY_REACTION: 14,
    CALL_STARTED: 15,
    CALL_ENDED: 16,
    CALL_PARTICIPANT_JOINED: 17,
    CALL_PARTICIPANT_LEFT: 18,
}

module.exports.POPULATE_REDUCED_FIELDS = {
    USER: '_id username avatar',
    HOSTED_FURNACE: '_id name description discoverable override adultOnly enableWall approved',
}

module.exports.BUCKET_TYPE = {
    IMAGE: 0,
    VIDEO: 1,
    FILE: 2,
    AVATAR: 3,
    BACKGROUND: 4,
    KEYCHAIN_BACKUP: 5,
    LOG_DETAIL: 6
}

module.exports.TAG_TYPE = {
    ICM: 0,
    REACTION: 1,
    EDIT: 2,
    REPLY_REACTION: 3,
}

module.exports.BLOB_AUTH_TYPE = {
    CIRCLE: 0,
    USER: 1,
    USERCIRCLE: 2,
    AVATAR: 3,
}

module.exports.BLOB_LOCATION = {
    S3: 'S3',
    GRIDFS: 'GRIDFS',
    FILE: 'FILE',
    PRIVATE_S3: 'PS3',
    PRIVATE_WASABI: 'PW',
}


module.exports.CIRCLEOBJECT_TYPE = {
    CIRCLEIMAGE: 'circleimage',
    CIRCLEALBUM: 'circlealbum',
    CIRCLEVIDEO: 'circlevideo',
    CIRCLEMESSAGE: 'circlemessage',
    CIRCLEGIF: 'circlegif',
    CIRCLERECIPE: 'circlerecipe',
    CIRCLEFILE: 'circlefile',
    CIRCLEVOTE: 'circlevote',
    CIRCLELIST: 'circlelist',
    CIRCLELINK: 'circlelink',
    CIRCLEREVIEW: 'circlereview',
    CIRCLECREDENTIAL: 'circlecredential',
    CIRCLEEVENT: 'circleevent',
    SYSTEMMESSAGE: 'systemmessage',
    CIRCLEAGORACALL: 'circleagoracall'
}


module.exports.CIRCLEOBJECT_ENGLISH = {
    CIRCLEIMAGE: 'image',
    CIRCLEALBUM: 'album',
    CIRCLEVIDEO: 'video',
    CIRCLEMESSAGE: 'message',
    CIRCLEGIF: 'gif',
    CIRCLERECIPE: 'recipe',
    CIRCLEVOTE: 'vote',
    CIRCLELIST: 'list',
    CIRCLEFILE: 'file',
    CIRCLELINK: 'link',
    CIRCLEREVIEW: 'review',
    CIRCLEEVENT: 'event',
}

module.exports.VOTE_TYPE = {
    STANDARD: 'standard',
    ADD_MEMBER: 'invitation',
    REMOVE_MEMBER: 'remove_member',
    DELETE_CIRCLE: 'delete_circle',
    SECURITY_SETTING: 'security_setting',
    PRIVACY_SETTING: 'privacy_setting',
    SECURITY_SETTING_MODEL: 'security_setting_model',
    PRIVACY_SETTING_MODEL: 'privacy_setting_model',
}

module.exports.CIRCLE_SETTING_VALUE = {
    ALLOWED: 'allowed',
    DISALLOWED: 'disallowed',
}

module.exports.CIRCLE_SETTING_CHANGE_TYPE = {
    PRIVACY: 0,
    SECURITY: 1,
}



// module.exports.DISAPPEARING_TIMER_STRING = {
//     OFF: 'off',
//     FOUR_HOURS: '4 hours',
//     EIGHT_HOURS: '8 hours',
//     ONE_DAY: '1 day',
//     ONE_WEEK: '1 week',
//     THIRTY_DAYS: '30 days',
//     NINETY_DAYS: '90 days',
//     SIX_MONTHS: '6 months',
//     ONE_YEAR: '1 year',
// }


module.exports.DISAPPEARING_TIMER = {
    OFF: 0,
    FOUR_HOURS: 4,
    EIGHT_HOURS: 8,
    ONE_DAY: 24,
    ONE_WEEK: 168,
    THIRTY_DAYS: 720,
    NINETY_DAYS: 2160,
    SIX_MONTHS: 4320,
    ONE_YEAR: 8760,
}

module.exports.CIRCLE_SETTING = {
    TOGGLE_MEMBER_POSTING: 'toggleMemberPosting',
    TOGGLE_MEMBER_REACTING: 'toggleMemberReacting',
    TOGGLE_ENTRY_VOTE: 'toggleEntryVote',
    PRIVACY_SHAREIMAGE: 'privacyShareImage',
    PRIVACY_VOTING_MODEL: 'privacyVotingModel',
    PRIVACY_SHAREURL: 'privacyShareURL',
    //SETTING_SHAREURL_MODEL:  'settingShareURLModel',
    PRIVACY_SHAREGIF: 'privacyShareGif',
    // SETTING_SHAREGIF_MODEL:'settingShareGifModel',
    PRIVACY_COPYTEXT: 'privacyCopyText',
    //SECURITY_2FA: 'security2FA',
    //SETTING_COPYTEXT_MODEL: 'settingCopyTextModel',
    PRIVACY_DISAPPEARING_TIMER: 'privacyDisappearingTimer',
    SECURITY_MINPASSWORD: 'securityMinPassword',
    SECURITY_VOTING_MODEL: 'securityVotingModel',
    SECURITY_DAYSPASSWORDVALID: 'securityDaysPasswordValid',
    //SECURITY_DAYSPASSWORDVALID_MODEL:'securityDaysPasswordValidModel',
    SECURITY_TOKENEXPIRATIONDAYS: 'securityTokenExpirationDays',
    //SECURITY_TOKENEXPIRATIONDAYS_MODEL :'securityTokenExpirationDaysModel',
    SECURITY_LOGINATTEMPTS: 'securityLoginAttempts',
    //SECURITY_LOGINATTEMPTSMODEL :'securityLoginAttemptsModel',
}

module.exports.NETWORK_REQUEST_STATUS = {
    PENDING: 0,
    APPROVED: 1,
    DECLINED: 2,
    CANCELED: 3,
    CANCELED_AFTER_DECLINED: 4,
}

module.exports.CIRCLE_SETTING_ENGLISH = {
    PRIVACY_SHAREIMAGE: 'Sharing Images',
    PRIVACY_VOTING_MODEL: 'the Privacy Settings voting model',
    PRIVACY_SHAREURL: 'Sharing Urls',
    PRIVACY_CIRCLENAME: 'Include Circle name in notification',
    PRIVACY_INVITATION_TIMEOUT: 'Timeout invitation',
    //PRIVACY_SHAREURL_MODEL:  'the Sharing Images voting model',
    PRIVACY_SHAREGIF: 'Sharing Gifs',
    // PRIVACY_SHAREGIF_MODEL:'the Sharing Gifs voting model',
    PRIVACY_COPYTEXT: 'Copying Message Text',
    //PRIVACY_COPYTEXT_MODEL: 'the Copying Message Text voting model',
    SECURITY_DISAPPEARING_TIMER: 'Disappearing Message Timer',
    SECURITY_MINPASSWORD: 'Minimum Password Length',
    //SECURITY_VOTING_MODEL: 'the Security Settings voting model',
    SECURITY_DAYSPASSWORDVALID: 'Password Reset',
    //SECURITY_DAYSPASSWORDVALID_MODEL:'the Password Reset voting model',
    SECURITY_TOKENEXPIRATIONDAYS: 'Days Stay Logged In',
    //SECURITY_TOKENEXPIRATIONDAYS_MODEL :'the Days Stay Logged In',
    SECURITY_PASSWORDATTEMPTS: 'Password Attempts',
    SECURITY_VOTING_MODEL: 'the Security Settings voting model',
}

module.exports.VOTE_MODEL = {
    UNANIMOUS: 'unanimous',
    MAJORITY: 'majority',
    POLL: 'poll',
}

module.exports.CIRCLE_TYPE = {
    STANDARD: 'standard',
    TEMPORARY: 'temporary',
    VAULT: 'vault',
    EVERYONE: 'everyone',
    WALL: 'wall',
}

module.exports.CIRCLE_OWNERSHIP = {
    MEMBERS: 'members',
    OWNER: 'owner',
}

module.exports.CIRCLE_RETENTION = {
    DEVICE_ONLY: 0,
    TEN_GB: 10, //$4.49
    TWENTY_FIVE_GB: 25, //$10.49
    FIFTY_GB: 50, //$19.99
    SEVENTY_FIVE_GB: 75, //$5
    ONE_HUNDRED_GB: 100, //$39,
    TWO_HUNDRED_GB: 250, //100,
    FIVE_HUNDRED_GB: 500, //100,
    ONE_TB: 1000, //100,
    TWO_TB: 2000 //100,
}

module.exports.SUBSCRIPTION = {
    //needs to directly match app and play store
    PRIVACY_PLUS: 'privacy_plus',
}

module.exports.SUBSCRIPTION_STATUS = {
    PENDING: 0,
    ACTIVE: 1,
    PAUSED: 2,
    CANCELED: 3,
}

module.exports.PURCHASE_OBJECT_STATUS = {
    PENDING: 0,
    PURCHASED: 1,
    CANCELED: 2,
  }

module.exports.ACCOUNT_TYPE = {
    FREE: 0,
    PREMIUM: 1,
}

module.exports.ROLE = {
    MEMBER: 0,
    ADMIN: 1,
    OWNER: 2,
    IC_ADMIN: 3,
    DEBUG: 4,
}

module.exports.INVITATION_STATUS = {
    CANCELED: 'canceled',
    DECLINED: 'declined',
    ACCEPTED: 'accepted',
    BLOCKED: 'blocked',
    PENDING: 'pending',
    //INVITED: 'invited',
}

module.exports.RESULTS_STRING = {
    SUCCESS: 'success',
    fail: 'fail',
}

module.exports.RESULTS_INT = {
    SUCCESS: 1,
    FAIL: 0,
}

module.exports.ACTION_REQUIRED = {
    SETUP_PASSWORD_ASSIST: 1,
    HELP_WITH_RESET: 2,
    EXPORT_KEYS: 3,
    CHANGE_GENERATED: 4,
    USER_JOINED_NETWORK: 5,
    NETWORK_REQUEST_APPROVED: 6,
    USER_REQUESTED_JOIN_NETWORK: 7,
    USER_REQUESTED_EMPTY: 8,
}

module.exports.REMINDER_TYPE = {
    DUE_IN_HOUR: 1,
    DUE_IN_DAY: 2,
}

module.exports.DEVICE_PLATFORM = {
    iOS: 'iOS',
    ANDROID: 'android',
    MACOS: 'macos',
}