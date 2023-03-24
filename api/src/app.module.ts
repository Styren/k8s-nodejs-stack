import { AppController } from './app.controller';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AppService } from './app.service';
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HealthModule } from './health.module';
import { PrometheusModule } from '@willsoto/nestjs-prometheus';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule, PrometheusModule.register()],
      useFactory: async (configService: ConfigService) => ({
        type: 'postgres',
        port: 5432,
        replication: {
          master: {
            host: configService.get<string>('POSTGRES_HOST'),
            username: configService.get<string>('POSTGRES_USER'),
            password: configService.get<string>('POSTGRES_PASSWORD'),
            database: configService.get<string>('POSTGRES_DB'),
          },
          slaves: configService.get<string>('POSTGRES_REPLICA_HOST')
            ? [
                {
                  host: configService.get<string>('POSTGRES_REPLICA_HOST'),
                  username: configService.get<string>('POSTGRES_USER'),
                  password: configService.get<string>('POSTGRES_PASSWORD'),
                  database: configService.get<string>('POSTGRES_DB'),
                },
              ]
            : [],
        },
        entities: [],
        synchronize: true,
      }),
      inject: [ConfigService],
    }),
    ConfigModule.forRoot(),
    HealthModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
