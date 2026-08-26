# pawprint

A new Flutter project.

## Supabase

Supabase is configured for project `mtyouhpigpohzjifhdxz` and schema
`treatfeedtails`. The public publishable key is configured by default, or can
be overridden at build or run time:

```text
flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Never use a service-role key in the Flutter app.

## Prisma database connection

Prisma is configured for the Supabase PostgreSQL database at
`db.mtyouhpigpohzjifhdxz.supabase.co:5432`, database `postgres`, user
`postgres`, and schema `treatfeedtails`. Copy `.env.example` to `.env`, replace
`[YOUR-PASSWORD]`, then run:

```text
npm install
npx prisma generate
npx prisma validate
```

Do not commit `.env` or use the database password in Flutter or browser code.

The dog record table is defined in
`supabase/migrations/001_primary_dog_details.sql`. Apply it with the Supabase
CLI or run it in the Supabase SQL Editor.

In the Supabase dashboard, add `treatfeedtails` under **Settings -> API ->
Exposed schemas** so the Flutter client can reach the table.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
