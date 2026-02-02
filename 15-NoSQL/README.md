# N15 — MongoDB: Gym Database (Collections, CRUD, Queries, Cleanup)

This homework demonstrates how to run MongoDB in Docker, create a database with multiple collections, insert documents, handle duplicate data, and execute required queries with verification output.

---

## Environment Overview

- Host OS: macOS (Docker Desktop)
- MongoDB: **7.0**
- Containerized DB via Docker Compose
- Access via `mongosh`

---

## Project Structure

```text
15-NoSQL/db_related/
└─  docker-compose.yml
```

---

## Step 1: Start MongoDB with Docker Compose

Start the database:

```bash
docker compose up -d
docker compose ps
```

Result:

```text
NAME        IMAGE     COMMAND                  SERVICE   CREATED          STATUS          PORTS
gym-mongo   mongo:7   "docker-entrypoint.s…"   mongo     53 seconds ago   Up 52 seconds   0.0.0.0:27017->27017/tcp, [::]:27017->27017/tcp
```

---

## Step 2: Create Database and Collections

Connect to Mongo shell inside the container:

```bash
docker exec -it gym-mongo mongosh -u root -p root --authenticationDatabase admin
```

Create database and collections:

```javascript
use gymDatabase
db.createCollection("clients")
db.createCollection("memberships")
db.createCollection("workouts")
db.createCollection("trainers")
show collections
```

Result:

```text
switched to db gymDatabase
{ ok: 1 }
{ ok: 1 }
{ ok: 1 }
{ ok: 1 }
clients
memberships
trainers
workouts
```

---

## Step 3: Insert Documents

### Insert clients

```javascript
db.clients.insertMany([
  { client_id: 1, name: "Oleh Petrenko", age: 28, email: "oleh.petrenko@example.com" },
  { client_id: 2, name: "Iryna Shevchenko", age: 34, email: "iryna.shevchenko@example.com" },
  { client_id: 3, name: "Taras Koval", age: 41, email: "taras.koval@example.com" },
  { client_id: 4, name: "Marta Bondarenko", age: 31, email: "marta.bondarenko@example.com" }
])
```

Result:

```text
{
  acknowledged: true,
  insertedIds: {
    '0': ObjectId('6980e2469bfb24a6c3284d0c'),
    '1': ObjectId('6980e2469bfb24a6c3284d0d'),
    '2': ObjectId('6980e2469bfb24a6c3284d0e'),
    '3': ObjectId('6980e2469bfb24a6c3284d0f')
  }
}
```

### Insert workouts (initial insert)

```javascript
db.workouts.insertMany([
  { workout_id: 201, description: "Full body strength training", difficulty: "Medium" },
  { workout_id: 202, description: "HIIT cardio intervals", difficulty: "Hard" },
  { workout_id: 203, description: "Mobility + stretching routine", difficulty: "Easy" },
  { workout_id: 204, description: "Upper body hypertrophy", difficulty: "Medium" }
])
```

Result:

```text
{
  acknowledged: true,
  insertedIds: {
    '0': ObjectId('6980e24f9bfb24a6c3284d10'),
    '1': ObjectId('6980e24f9bfb24a6c3284d11'),
    '2': ObjectId('6980e24f9bfb24a6c3284d12'),
    '3': ObjectId('6980e24f9bfb24a6c3284d13')
  }
}
```

### Insert workouts (accidental duplicate insert)

```javascript
db.workouts.insertMany([
  { workout_id: 201, description: "Full body strength training", difficulty: "Medium" },
  { workout_id: 202, description: "HIIT cardio intervals", difficulty: "Hard" },
  { workout_id: 203, description: "Mobility + stretching routine", difficulty: "Easy" },
  { workout_id: 204, description: "Upper body hypertrophy", difficulty: "Medium" }
])
```

Result:

```text
{
  acknowledged: true,
  insertedIds: {
    '0': ObjectId('6980e2549bfb24a6c3284d14'),
    '1': ObjectId('6980e2549bfb24a6c3284d15'),
    '2': ObjectId('6980e2549bfb24a6c3284d16'),
    '3': ObjectId('6980e2549bfb24a6c3284d17')
  }
}
```

### Insert trainers

```javascript
db.trainers.insertMany([
  { trainer_id: 301, name: "Andrii Moroz", specialization: "Strength" },
  { trainer_id: 302, name: "Olena Lysенко", specialization: "Yoga" },
  { trainer_id: 303, name: "Danylo Romanenko", specialization: "Cardio" }
])
```

Result:

```text
{
  acknowledged: true,
  insertedIds: {
    '0': ObjectId('6980e2589bfb24a6c3284d18'),
    '1': ObjectId('6980e2589bfb24a6c3284d19'),
    '2': ObjectId('6980e2589bfb24a6c3284d1a')
  }
}
```

### Insert memberships

```javascript
db.memberships.insertMany([
  { membership_id: 101, client_id: 1, start_date: ISODate("2026-01-01"), end_date: ISODate("2026-06-30"), type: "Standard" },
  { membership_id: 102, client_id: 2, start_date: ISODate("2025-11-15"), end_date: ISODate("2026-11-14"), type: "Premium" },
  { membership_id: 103, client_id: 3, start_date: ISODate("2026-02-01"), end_date: ISODate("2026-04-30"), type: "Trial" },
  { membership_id: 104, client_id: 4, start_date: ISODate("2026-01-10"), end_date: ISODate("2026-07-09"), type: "Standard" }
])
```

Result:

```text
{
  acknowledged: true,
  insertedIds: {
    '0': ObjectId('6980e2979bfb24a6c3284d1b'),
    '1': ObjectId('6980e2979bfb24a6c3284d1c'),
    '2': ObjectId('6980e2979bfb24a6c3284d1d'),
    '3': ObjectId('6980e2979bfb24a6c3284d1e')
  }
}
```

### Verify document counts

```javascript
db.clients.countDocuments()
db.memberships.countDocuments()
db.workouts.countDocuments()
db.trainers.countDocuments()
```

Result:

```text
clients: 4
memberships: 4
workouts: 8
trainers: 3
```

---

## Step 4: Cleanup Duplicate Workouts

Remove duplicates by `workout_id` (keep one document per id):

```javascript
db.workouts.aggregate([
  { $group: { _id: "$workout_id", ids: { $push: "$_id" }, count: { $sum: 1 } } },
  { $match: { count: { $gt: 1 } } }
]).forEach(g => {
  g.ids.shift(); // keep first
  db.workouts.deleteMany({ _id: { $in: g.ids } });
});
```

Verify workouts after cleanup:

```javascript
db.workouts.countDocuments()
db.workouts.find({}, { _id: 0, workout_id: 1, description: 1, difficulty: 1 }).sort({ workout_id: 1 })
```

Result:

```text
4
[
  { workout_id: 201, description: 'Full body strength training', difficulty: 'Medium' },
  { workout_id: 202, description: 'HIIT cardio intervals', difficulty: 'Hard' },
  { workout_id: 203, description: 'Mobility + stretching routine', difficulty: 'Easy' },
  { workout_id: 204, description: 'Upper body hypertrophy', difficulty: 'Medium' }
]
```

---

## Step 5: Required Queries

### Query 1 — Clients older than 30

```javascript
db.clients.find(
  { age: { $gt: 30 } },
  { _id: 0, client_id: 1, name: 1, age: 1, email: 1 }
).sort({ age: 1 })
```

Result:

```text
[
  { client_id: 4, name: 'Marta Bondarenko', age: 31, email: 'marta.bondarenko@example.com' },
  { client_id: 2, name: 'Iryna Shevchenko', age: 34, email: 'iryna.shevchenko@example.com' },
  { client_id: 3, name: 'Taras Koval', age: 41, email: 'taras.koval@example.com' }
]
```

---

### Query 2 — Workouts with Medium difficulty

```javascript
db.workouts.find(
  { difficulty: "Medium" },
  { _id: 0, workout_id: 1, description: 1, difficulty: 1 }
).sort({ workout_id: 1 })
```

Result:

```text
[
  { workout_id: 201, description: 'Full body strength training', difficulty: 'Medium' },
  { workout_id: 204, description: 'Upper body hypertrophy', difficulty: 'Medium' }
]
```

---

### Query 3 — Membership info for client_id = 2

```javascript
db.memberships.find(
  { client_id: 2 },
  { _id: 0, membership_id: 1, client_id: 1, start_date: 1, end_date: 1, type: 1 }
)
```

Result:

```text
[
  {
    membership_id: 102,
    client_id: 2,
    start_date: ISODate('2025-11-15T00:00:00.000Z'),
    end_date: ISODate('2026-11-14T00:00:00.000Z'),
    type: 'Premium'
  }
]
```

---

## Conclusion

In this homework, the following was implemented and verified:

- MongoDB database `gymDatabase` created in Docker
- Required collections created and populated with documents
- Duplicate workout data detected and cleaned up
- Required queries executed with verified outputs
