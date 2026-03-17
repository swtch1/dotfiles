// Generated from alerts.proto — DO NOT EDIT
export var AlertSeverity;
(function (AlertSeverity) {
    AlertSeverity[AlertSeverity["INFO"] = 0] = "INFO";
    AlertSeverity[AlertSeverity["WARNING"] = 1] = "WARNING";
    AlertSeverity[AlertSeverity["CRITICAL"] = 2] = "CRITICAL";
})(AlertSeverity || (AlertSeverity = {}));
export var AlertState;
(function (AlertState) {
    AlertState[AlertState["OK"] = 0] = "OK";
    AlertState[AlertState["PENDING"] = 1] = "PENDING";
    AlertState[AlertState["FIRING"] = 2] = "FIRING";
    AlertState[AlertState["RESOLVED"] = 3] = "RESOLVED";
})(AlertState || (AlertState = {}));
export var NotificationChannel;
(function (NotificationChannel) {
    NotificationChannel[NotificationChannel["SLACK"] = 0] = "SLACK";
    NotificationChannel[NotificationChannel["EMAIL"] = 1] = "EMAIL";
    NotificationChannel[NotificationChannel["PAGERDUTY"] = 2] = "PAGERDUTY";
    NotificationChannel[NotificationChannel["WEBHOOK"] = 3] = "WEBHOOK";
})(NotificationChannel || (NotificationChannel = {}));
