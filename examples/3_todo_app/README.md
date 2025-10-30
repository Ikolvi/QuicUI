# Todo App Example

## Overview
A todo list application demonstrating:
- **List Rendering**: Dynamic ListView with itemBuilder
- **CRUD Operations**: Create, read, update, delete todos
- **State Management**: Managing list state
- **Item Actions**: Toggle completion, delete items
- **User Interaction**: Text input with add button

## Features
✅ Add new todos  
✅ Mark todos as complete/incomplete  
✅ Delete todos  
✅ Strike-through completed items  
✅ Dynamic list rendering  
✅ Persistent state  

## JSON Structure

### ListView with ItemBuilder
```json
{
  "id": "list_view_todos",
  "type": "ListView",
  "properties": {
    "padding": 8,
    "itemCount": 10
  },
  "stateBinding": {
    "variable": "todos",
    "defaultValue": []
  },
  "itemBuilder": {
    "id": "todo_item",
    "type": "Card",
    "children": [...]
  }
}
```

### List Item Template
```json
"itemBuilder": {
  "id": "todo_item",
  "type": "Card",
  "children": [
    {
      "id": "list_tile",
      "type": "ListTile",
      "children": [
        {"id": "checkbox", "type": "Checkbox"},
        {"id": "title", "type": "Text"},
        {"id": "delete_button", "type": "IconButton"}
      ]
    }
  ]
}
```

## Key Concepts

### Dynamic List Binding
```json
"stateBinding": {
  "variable": "todos",
  "defaultValue": []
}
```
Binds ListView to array state, updates automatically.

### Item Data Access
```json
"properties": {
  "data": "{todo.title}",
  "value": "{todo.completed}"
}
```
Access item properties using curly brace syntax.

### CRUD Actions
- **addTodo**: Create new todo
- **toggleTodo**: Update completion status
- **deleteTodo**: Remove todo from list

### Todo Object Structure
```json
{
  "id": "unique-id",
  "title": "Task title",
  "completed": false,
  "createdAt": "2024-01-01",
  "dueDate": "2024-01-10"
}
```

## State Management

### Initial State
```json
"todos": [
  {
    "id": "1",
    "title": "Learn QuicUI",
    "completed": false
  },
  {
    "id": "2",
    "title": "Build an app",
    "completed": false
  }
]
```

### After Add Action
- New todo with unique ID added to array
- List rebuilds automatically
- Input field cleared

### After Toggle Action
- Todo's `completed` flag toggled
- Text style changes (strikethrough)
- List updates without rebuild

## Testing
This app is tested with:
- ListView rendering tests
- Item binding tests
- CRUD operation tests
- State update tests
- Dynamic list tests

See `test/examples/todo_app_test.dart` for implementation.

## Running the Example
```bash
flutter run --dart-define=QUICUI_CONFIG=todo_app.json
```

## Advanced Features
- Filter todos (all, active, completed)
- Sort by date or title
- Search todos
- Categorize todos
- Add due dates
- Set priority levels

## Next Steps
- Add filtering options
- Implement sorting
- Add search functionality
- Persist data to local database
- Add categories/tags
- Implement undo/redo
