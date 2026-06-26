DROP INDEX "user_email_unique";--> statement-breakpoint
ALTER TABLE `program` ALTER COLUMN "startAt" TO "startAt" text NOT NULL;--> statement-breakpoint
CREATE UNIQUE INDEX `user_email_unique` ON `user` (`email`);--> statement-breakpoint
ALTER TABLE `program` ALTER COLUMN "endAt" TO "endAt" text NOT NULL;