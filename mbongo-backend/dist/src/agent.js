"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const agent_1 = require("@21st-sdk/agent");
const zod_1 = require("zod");
exports.default = (0, agent_1.agent)({
    model: "claude-sonnet-4-6",
    systemPrompt: "You are a helpful coding assistant.",
    tools: {
        add: (0, agent_1.tool)({
            description: "Add two numbers",
            inputSchema: zod_1.z.object({ a: zod_1.z.number(), b: zod_1.z.number() }),
            execute: async ({ a, b }) => ({
                content: [{ type: "text", text: `${a + b}` }],
            }),
        }),
    },
});
//# sourceMappingURL=agent.js.map