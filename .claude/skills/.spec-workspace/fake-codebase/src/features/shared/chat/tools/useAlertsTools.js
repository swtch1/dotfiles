import { useMemo, useRef, useEffect } from "react";
function useLatestRef(value) {
    const ref = useRef(value);
    useEffect(() => {
        ref.current = value;
    });
    return ref;
}
export function useAlertsTools(options) {
    const optionsRef = useLatestRef(options);
    return useMemo(() => [
        {
            name: "navigate_to_tab",
            description: "Navigate to a tab on the Alerts page",
            parameters: {
                tab: {
                    type: "string",
                    description: "Tab to navigate to",
                    required: true,
                    enum: ["rules", "events"],
                },
            },
            handler: async (args) => {
                const tab = args.tab;
                const { history } = optionsRef.current;
                history.push({ hash: `#alerts-${tab}` });
                return { success: true, message: `Navigated to ${tab} tab` };
            },
        },
        {
            name: "select_rule",
            description: "Select an alert rule to view its details",
            parameters: {
                ruleId: {
                    type: "string",
                    description: "The alert rule ID",
                    required: true,
                },
            },
            handler: async (args) => {
                const ruleId = args.ruleId;
                const { onSelectRule, rules } = optionsRef.current;
                const rule = rules.find((r) => r.id === ruleId);
                if (!rule)
                    return { success: false, message: `Rule ${ruleId} not found` };
                onSelectRule(ruleId);
                return { success: true, message: `Selected rule: ${rule.name}` };
            },
        },
        {
            name: "acknowledge_event",
            description: "Acknowledge a firing alert event",
            parameters: {
                eventId: {
                    type: "string",
                    description: "The alert event ID",
                    required: true,
                },
            },
            confirmationRequired: true,
            handler: async (args) => {
                const eventId = args.eventId;
                try {
                    await optionsRef.current.onAcknowledge(eventId, "current-user");
                    return {
                        success: true,
                        message: `Alert event ${eventId} acknowledged`,
                    };
                }
                catch (e) {
                    return {
                        success: false,
                        message: `Failed to acknowledge: ${e.message}`,
                    };
                }
            },
        },
        {
            name: "mute_rule",
            description: "Mute an alert rule for a specified duration",
            parameters: {
                ruleId: {
                    type: "string",
                    description: "The alert rule ID",
                    required: true,
                },
                duration: {
                    type: "string",
                    description: 'Duration to mute (e.g., "1h", "30m", "1d")',
                    required: true,
                },
            },
            confirmationRequired: true,
            handler: async (args) => {
                const ruleId = args.ruleId;
                const duration = args.duration;
                const until = computeMuteUntil(duration);
                try {
                    await optionsRef.current.onMuteRule(ruleId, until);
                    return {
                        success: true,
                        message: `Rule ${ruleId} muted until ${until}`,
                    };
                }
                catch (e) {
                    return {
                        success: false,
                        message: `Failed to mute: ${e.message}`,
                    };
                }
            },
        },
    ], []);
}
function computeMuteUntil(duration) {
    const match = duration.match(/^(\d+)(m|h|d)$/);
    if (!match)
        throw new Error(`Invalid duration format: ${duration}`);
    const [, amount, unit] = match;
    const ms = { m: 60000, h: 3600000, d: 86400000 }[unit];
    return new Date(Date.now() + parseInt(amount) * ms).toISOString();
}
