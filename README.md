# SwiftTrends

Chat with your database using AI. Shake your phone to open a chat interface that can query your Postgres database and answer questions about your data.

## Setup

### 1. Register your database

```bash
curl -X POST https://swift-trends-server-67c54feffa03.herokuapp.com/register \
  -H "Content-Type: application/json" \
  -d '{
    "database_url": "postgres://user:password@host:5432/dbname",
    "openai_key": "sk-..."
  }'
```

This returns an API key:

```json
{"api_key": "tr_abc123..."}
```

### 2. Add to your app

```swift
import SwiftTrends

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .trendsChat(apiKey: "tr_abc123...")
        }
    }
}
```

### 3. Shake to chat

Shake your device to open the chat interface. Ask questions like:

- "How many users signed up this week?"
- "What's my revenue by month?"
- "Show me the top 10 products by sales"

The AI will query your database and respond with answers.

## How it works

```
Your App → SwiftTrends SDK → Hosted Server → Your Database
                                   ↓
                                OpenAI
```

1. Your database credentials are stored securely on our server, linked to your API key
2. When you ask a question, the AI generates a SQL query
3. The query runs against your database (read-only, SELECT only)
4. The AI interprets the results and responds

## Security

- Your database credentials never touch your app binary
- Only SELECT queries are allowed
- API keys can be revoked at any time
- All traffic is over HTTPS

## Requirements

- iOS 18+
- A Postgres database
- An OpenAI API key
