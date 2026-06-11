import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { AccountController } from './account.controller';

@Module({
  providers: [UsersService],
  controllers: [UsersController, AccountController],
  exports: [UsersService],
})
export class UsersModule {}
