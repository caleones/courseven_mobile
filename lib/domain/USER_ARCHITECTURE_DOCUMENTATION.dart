/*
ARQUITECTURA DE USUARIO - CourSEVEN
===================================

CLEAN ARCHITECTURE IMPLEMENTADA:

1. DOMAIN LAYER (Capa de Dominio)
   ├── models/user.dart
   │   ├── enum UserRole (student, teacher)
   │   ├── class User (entidad principal)
   │   ├── Propiedades: id, studentId, email, firstName, lastName, roles, etc.
   │   ├── Métodos: isStudent, isTeacher, canCreateMoreCourses, etc.
   │   └── Lógica de negocio: máximo 3 cursos como profesor
   │
   ├── repositories/user_repository.dart
   │   └── Abstract class con contrato de repositorio
   │
   └── use_cases/
       ├── register_user_use_case.dart
       ├── login_user_use_case.dart
       └── manage_user_roles_use_case.dart

2. DATA LAYER (Capa de Datos)
   └── models/user_model.dart
       ├── Extends User domain entity
       ├── fromJson/toJson serialization
       ├── Parseo de roles desde/hacia JSON
       └── Conversión hacia entidad de dominio

CARACTERÍSTICAS PRINCIPALES:

✅ USUARIO UNIVERSAL:
   - Un usuario puede ser estudiante Y profesor simultáneamente
   - Estudiante: cursos ilimitados
   - Profesor: máximo 3 cursos

✅ MANEJO DE ROLES:
   - Enum UserRole (student, teacher)
   - Lista de roles por usuario
   - Validaciones de límites de enseñanza
   - Promoción/degradación de roles

✅ CASOS DE USO:
   - RegisterUserUseCase: Registro con validaciones
   - LoginUserUseCase: Autenticación
   - ManageUserRolesUseCase: Gestión de roles y estadísticas

✅ VALIDACIONES:
   - Formato de email
   - Formato de student ID
   - Disponibilidad de email/studentId
   - Límites de cursos para profesores

✅ SERIALIZACIÓN JSON:
   - Conversión bidireccional
   - Manejo de roles como array de strings
   - Campos de estadísticas

PRÓXIMOS PASOS:
1. Implementar UserRepositoryImpl (data layer)
2. Integrar con Roble API
3. Actualizar AuthController para usar estos casos de uso
4. Implementar UI de login/register
5. Añadir manejo de contraseñas y tokens

ESTRUCTURA DE JSON ESPERADA:
{
  "id": "user_123",
  "student_id": "202012345",
  "email": "usuario@uninorte.edu.co",
  "first_name": "Juan",
  "last_name": "Pérez",
  "profile_image_url": null,
  "is_active": true,
  "last_login_at": "2025-09-15T10:30:00Z",
  "created_at": "2025-09-01T08:00:00Z",
  "updated_at": "2025-09-15T10:30:00Z",
  "roles": ["student", "teacher"],
  "max_teaching_courses": 3,
  "current_teaching_courses": 1,
  "enrolled_courses_count": 5
}
*/
