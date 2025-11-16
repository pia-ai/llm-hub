# llm-hub

${description}


```
llm-hub/
├── app/
│   ├── bootstrap/          # Application entry point
│   ├── biz/                # Business layer
│   │   ├── web/            # Web controllers
│   │   ├── service-impl/   # Service implementations
│   │   └── shared/         # Business shared code
│   ├── core/               # Core layer
│   │   ├── service/        # Core services
│   │   └── model/          # Domain models
│   ├── common/             # Common layer
│   │   ├── util/           # Utilities
│   │   ├── service/        # Service interfaces
│   │   │   ├── facade/     # Service facades
│   │   │   └── integration/# External integrations
│   │   └── dal/            # Data access layer
│   └── test/               # Test module
└── pom.xml                 # Parent POM
```



- JDK 17 or higher
- Maven 3.6+
- MySQL 8.0+ (for database)


```bash
mvn clean install
```


```bash
cd app/bootstrap
mvn spring-boot:run
```


- **bootstrap**: Application entry, depends on biz-web and common-dal
- **biz-web**: Web layer, depends on biz-service-impl, biz-shared, common-util, core-service
- **biz-service-impl**: Business logic, depends on core-service, core-model, common-dal
- **biz-shared**: Shared business code, depends on core-model, common-util
- **core-service**: Core services, depends on core-model, common-dal
- **core-model**: Domain models, minimal dependencies
- **common-util**: Utilities, no internal dependencies
- **common-service-facade**: Service interfaces, depends on core-model
- **common-service-integration**: External integrations, depends on core-model, common-util
- **common-dal**: Data access, depends on core-model


After generating the project, you need to manually rename `gitignore-template` to `.gitignore`:

```bash
mv gitignore-template .gitignore
```

