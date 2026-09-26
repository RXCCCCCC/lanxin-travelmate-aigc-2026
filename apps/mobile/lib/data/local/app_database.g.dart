// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalUsersTable extends LocalUsers
    with TableInfo<$LocalUsersTable, LocalUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, displayName, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_users';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalUser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUser(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalUsersTable createAlias(String alias) {
    return $LocalUsersTable(attachedDatabase, alias);
  }
}

class LocalUser extends DataClass implements Insertable<LocalUser> {
  final String id;
  final String displayName;
  final DateTime createdAt;
  const LocalUser({
    required this.id,
    required this.displayName,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalUsersCompanion toCompanion(bool nullToAbsent) {
    return LocalUsersCompanion(
      id: Value(id),
      displayName: Value(displayName),
      createdAt: Value(createdAt),
    );
  }

  factory LocalUser.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUser(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalUser copyWith({String? id, String? displayName, DateTime? createdAt}) =>
      LocalUser(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalUser copyWithCompanion(LocalUsersCompanion data) {
    return LocalUser(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUser(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, displayName, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUser &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.createdAt == this.createdAt);
}

class LocalUsersCompanion extends UpdateCompanion<LocalUser> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalUsersCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUsersCompanion.insert({
    required String id,
    required String displayName,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName);
  static Insertable<LocalUser> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUsersCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalUsersCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUsersCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryCapsulesTable extends MemoryCapsules
    with TableInfo<$MemoryCapsulesTable, MemoryCapsule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryCapsulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('agent'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    scope,
    source,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_capsules';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryCapsule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoryCapsule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryCapsule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $MemoryCapsulesTable createAlias(String alias) {
    return $MemoryCapsulesTable(attachedDatabase, alias);
  }
}

class MemoryCapsule extends DataClass implements Insertable<MemoryCapsule> {
  final String id;
  final String title;
  final String content;
  final String scope;
  final String source;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const MemoryCapsule({
    required this.id,
    required this.title,
    required this.content,
    required this.scope,
    required this.source,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['scope'] = Variable<String>(scope);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  MemoryCapsulesCompanion toCompanion(bool nullToAbsent) {
    return MemoryCapsulesCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      scope: Value(scope),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory MemoryCapsule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryCapsule(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      scope: serializer.fromJson<String>(json['scope']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'scope': serializer.toJson<String>(scope),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  MemoryCapsule copyWith({
    String? id,
    String? title,
    String? content,
    String? scope,
    String? source,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => MemoryCapsule(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    scope: scope ?? this.scope,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  MemoryCapsule copyWithCompanion(MemoryCapsulesCompanion data) {
    return MemoryCapsule(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      scope: data.scope.present ? data.scope.value : this.scope,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryCapsule(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('scope: $scope, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, content, scope, source, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryCapsule &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.scope == this.scope &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MemoryCapsulesCompanion extends UpdateCompanion<MemoryCapsule> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> content;
  final Value<String> scope;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const MemoryCapsulesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.scope = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryCapsulesCompanion.insert({
    required String id,
    required String title,
    required String content,
    required String scope,
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       content = Value(content),
       scope = Value(scope);
  static Insertable<MemoryCapsule> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? scope,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (scope != null) 'scope': scope,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryCapsulesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? content,
    Value<String>? scope,
    Value<String>? source,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return MemoryCapsulesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      scope: scope ?? this.scope,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryCapsulesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('scope: $scope, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileJsonMeta = const VerificationMeta(
    'profileJson',
  );
  @override
  late final GeneratedColumn<String> profileJson = GeneratedColumn<String>(
    'profile_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, userId, profileJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('profile_json')) {
      context.handle(
        _profileJsonMeta,
        profileJson.isAcceptableOrUnknown(
          data['profile_json']!,
          _profileJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profileJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      profileJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfile extends DataClass implements Insertable<UserProfile> {
  final String id;
  final String userId;
  final String profileJson;
  final DateTime updatedAt;
  const UserProfile({
    required this.id,
    required this.userId,
    required this.profileJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['profile_json'] = Variable<String>(profileJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      userId: Value(userId),
      profileJson: Value(profileJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfile(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      profileJson: serializer.fromJson<String>(json['profileJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'profileJson': serializer.toJson<String>(profileJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserProfile copyWith({
    String? id,
    String? userId,
    String? profileJson,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    profileJson: profileJson ?? this.profileJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserProfile copyWithCompanion(UserProfilesCompanion data) {
    return UserProfile(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      profileJson: data.profileJson.present
          ? data.profileJson.value
          : this.profileJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfile(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('profileJson: $profileJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, profileJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfile &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.profileJson == this.profileJson &&
          other.updatedAt == this.updatedAt);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfile> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> profileJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.profileJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    required String id,
    required String userId,
    required String profileJson,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       profileJson = Value(profileJson);
  static Insertable<UserProfile> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? profileJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (profileJson != null) 'profile_json': profileJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? profileJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      profileJson: profileJson ?? this.profileJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (profileJson.present) {
      map['profile_json'] = Variable<String>(profileJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('profileJson: $profileJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TripContextsTable extends TripContexts
    with TableInfo<$TripContextsTable, TripContext> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripContextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextJsonMeta = const VerificationMeta(
    'contextJson',
  );
  @override
  late final GeneratedColumn<String> contextJson = GeneratedColumn<String>(
    'context_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, userId, destination, contextJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trip_contexts';
  @override
  VerificationContext validateIntegrity(
    Insertable<TripContext> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationMeta);
    }
    if (data.containsKey('context_json')) {
      context.handle(
        _contextJsonMeta,
        contextJson.isAcceptableOrUnknown(
          data['context_json']!,
          _contextJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contextJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TripContext map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripContext(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      )!,
      contextJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_json'],
      )!,
    );
  }

  @override
  $TripContextsTable createAlias(String alias) {
    return $TripContextsTable(attachedDatabase, alias);
  }
}

class TripContext extends DataClass implements Insertable<TripContext> {
  final String id;
  final String userId;
  final String destination;
  final String contextJson;
  const TripContext({
    required this.id,
    required this.userId,
    required this.destination,
    required this.contextJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['destination'] = Variable<String>(destination);
    map['context_json'] = Variable<String>(contextJson);
    return map;
  }

  TripContextsCompanion toCompanion(bool nullToAbsent) {
    return TripContextsCompanion(
      id: Value(id),
      userId: Value(userId),
      destination: Value(destination),
      contextJson: Value(contextJson),
    );
  }

  factory TripContext.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripContext(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      destination: serializer.fromJson<String>(json['destination']),
      contextJson: serializer.fromJson<String>(json['contextJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'destination': serializer.toJson<String>(destination),
      'contextJson': serializer.toJson<String>(contextJson),
    };
  }

  TripContext copyWith({
    String? id,
    String? userId,
    String? destination,
    String? contextJson,
  }) => TripContext(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    destination: destination ?? this.destination,
    contextJson: contextJson ?? this.contextJson,
  );
  TripContext copyWithCompanion(TripContextsCompanion data) {
    return TripContext(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      contextJson: data.contextJson.present
          ? data.contextJson.value
          : this.contextJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripContext(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('destination: $destination, ')
          ..write('contextJson: $contextJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, destination, contextJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripContext &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.destination == this.destination &&
          other.contextJson == this.contextJson);
}

class TripContextsCompanion extends UpdateCompanion<TripContext> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> destination;
  final Value<String> contextJson;
  final Value<int> rowid;
  const TripContextsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.destination = const Value.absent(),
    this.contextJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TripContextsCompanion.insert({
    required String id,
    required String userId,
    required String destination,
    required String contextJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       destination = Value(destination),
       contextJson = Value(contextJson);
  static Insertable<TripContext> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? destination,
    Expression<String>? contextJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (destination != null) 'destination': destination,
      if (contextJson != null) 'context_json': contextJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TripContextsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? destination,
    Value<String>? contextJson,
    Value<int>? rowid,
  }) {
    return TripContextsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destination: destination ?? this.destination,
      contextJson: contextJson ?? this.contextJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (contextJson.present) {
      map['context_json'] = Variable<String>(contextJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripContextsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('destination: $destination, ')
          ..write('contextJson: $contextJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarStateMeta = const VerificationMeta(
    'avatarState',
  );
  @override
  late final GeneratedColumn<String> avatarState = GeneratedColumn<String>(
    'avatar_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardPayloadMeta = const VerificationMeta(
    'cardPayload',
  );
  @override
  late final GeneratedColumn<String> cardPayload = GeneratedColumn<String>(
    'card_payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    sender,
    body,
    avatarState,
    cardPayload,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('avatar_state')) {
      context.handle(
        _avatarStateMeta,
        avatarState.isAcceptableOrUnknown(
          data['avatar_state']!,
          _avatarStateMeta,
        ),
      );
    }
    if (data.containsKey('card_payload')) {
      context.handle(
        _cardPayloadMeta,
        cardPayload.isAcceptableOrUnknown(
          data['card_payload']!,
          _cardPayloadMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      avatarState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_state'],
      ),
      cardPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_payload'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessage extends DataClass implements Insertable<ChatMessage> {
  final String id;
  final String sessionId;
  final String sender;
  final String body;
  final String? avatarState;
  final String? cardPayload;
  final DateTime createdAt;
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.body,
    this.avatarState,
    this.cardPayload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['sender'] = Variable<String>(sender);
    map['text'] = Variable<String>(body);
    if (!nullToAbsent || avatarState != null) {
      map['avatar_state'] = Variable<String>(avatarState);
    }
    if (!nullToAbsent || cardPayload != null) {
      map['card_payload'] = Variable<String>(cardPayload);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      sender: Value(sender),
      body: Value(body),
      avatarState: avatarState == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarState),
      cardPayload: cardPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(cardPayload),
      createdAt: Value(createdAt),
    );
  }

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessage(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      sender: serializer.fromJson<String>(json['sender']),
      body: serializer.fromJson<String>(json['body']),
      avatarState: serializer.fromJson<String?>(json['avatarState']),
      cardPayload: serializer.fromJson<String?>(json['cardPayload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'sender': serializer.toJson<String>(sender),
      'body': serializer.toJson<String>(body),
      'avatarState': serializer.toJson<String?>(avatarState),
      'cardPayload': serializer.toJson<String?>(cardPayload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? sender,
    String? body,
    Value<String?> avatarState = const Value.absent(),
    Value<String?> cardPayload = const Value.absent(),
    DateTime? createdAt,
  }) => ChatMessage(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    sender: sender ?? this.sender,
    body: body ?? this.body,
    avatarState: avatarState.present ? avatarState.value : this.avatarState,
    cardPayload: cardPayload.present ? cardPayload.value : this.cardPayload,
    createdAt: createdAt ?? this.createdAt,
  );
  ChatMessage copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessage(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      sender: data.sender.present ? data.sender.value : this.sender,
      body: data.body.present ? data.body.value : this.body,
      avatarState: data.avatarState.present
          ? data.avatarState.value
          : this.avatarState,
      cardPayload: data.cardPayload.present
          ? data.cardPayload.value
          : this.cardPayload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessage(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('sender: $sender, ')
          ..write('body: $body, ')
          ..write('avatarState: $avatarState, ')
          ..write('cardPayload: $cardPayload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    sender,
    body,
    avatarState,
    cardPayload,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.sender == this.sender &&
          other.body == this.body &&
          other.avatarState == this.avatarState &&
          other.cardPayload == this.cardPayload &&
          other.createdAt == this.createdAt);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessage> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> sender;
  final Value<String> body;
  final Value<String?> avatarState;
  final Value<String?> cardPayload;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.sender = const Value.absent(),
    this.body = const Value.absent(),
    this.avatarState = const Value.absent(),
    this.cardPayload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required String sessionId,
    required String sender,
    required String body,
    this.avatarState = const Value.absent(),
    this.cardPayload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       sender = Value(sender),
       body = Value(body);
  static Insertable<ChatMessage> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? sender,
    Expression<String>? body,
    Expression<String>? avatarState,
    Expression<String>? cardPayload,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (sender != null) 'sender': sender,
      if (body != null) 'text': body,
      if (avatarState != null) 'avatar_state': avatarState,
      if (cardPayload != null) 'card_payload': cardPayload,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? sender,
    Value<String>? body,
    Value<String?>? avatarState,
    Value<String?>? cardPayload,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      avatarState: avatarState ?? this.avatarState,
      cardPayload: cardPayload ?? this.cardPayload,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (avatarState.present) {
      map['avatar_state'] = Variable<String>(avatarState.value);
    }
    if (cardPayload.present) {
      map['card_payload'] = Variable<String>(cardPayload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('sender: $sender, ')
          ..write('body: $body, ')
          ..write('avatarState: $avatarState, ')
          ..write('cardPayload: $cardPayload, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatSummariesTable extends ChatSummaries
    with TableInfo<$ChatSummariesTable, ChatSummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatSummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sessionId, summary];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatSummary> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatSummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatSummary(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
    );
  }

  @override
  $ChatSummariesTable createAlias(String alias) {
    return $ChatSummariesTable(attachedDatabase, alias);
  }
}

class ChatSummary extends DataClass implements Insertable<ChatSummary> {
  final String id;
  final String sessionId;
  final String summary;
  const ChatSummary({
    required this.id,
    required this.sessionId,
    required this.summary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['summary'] = Variable<String>(summary);
    return map;
  }

  ChatSummariesCompanion toCompanion(bool nullToAbsent) {
    return ChatSummariesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      summary: Value(summary),
    );
  }

  factory ChatSummary.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatSummary(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      summary: serializer.fromJson<String>(json['summary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'summary': serializer.toJson<String>(summary),
    };
  }

  ChatSummary copyWith({String? id, String? sessionId, String? summary}) =>
      ChatSummary(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        summary: summary ?? this.summary,
      );
  ChatSummary copyWithCompanion(ChatSummariesCompanion data) {
    return ChatSummary(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      summary: data.summary.present ? data.summary.value : this.summary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatSummary(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, summary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatSummary &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.summary == this.summary);
}

class ChatSummariesCompanion extends UpdateCompanion<ChatSummary> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> summary;
  final Value<int> rowid;
  const ChatSummariesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.summary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatSummariesCompanion.insert({
    required String id,
    required String sessionId,
    required String summary,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       summary = Value(summary);
  static Insertable<ChatSummary> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? summary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (summary != null) 'summary': summary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatSummariesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? summary,
    Value<int>? rowid,
  }) {
    return ChatSummariesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      summary: summary ?? this.summary,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatSummariesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('summary: $summary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AvatarStatesTable extends AvatarStates
    with TableInfo<$AvatarStatesTable, AvatarState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AvatarStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _energyMeta = const VerificationMeta('energy');
  @override
  late final GeneratedColumn<int> energy = GeneratedColumn<int>(
    'energy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _curiosityMeta = const VerificationMeta(
    'curiosity',
  );
  @override
  late final GeneratedColumn<int> curiosity = GeneratedColumn<int>(
    'curiosity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rapportMeta = const VerificationMeta(
    'rapport',
  );
  @override
  late final GeneratedColumn<int> rapport = GeneratedColumn<int>(
    'rapport',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _affectionMeta = const VerificationMeta(
    'affection',
  );
  @override
  late final GeneratedColumn<int> affection = GeneratedColumn<int>(
    'affection',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    energy,
    mood,
    curiosity,
    rapport,
    affection,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'avatar_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<AvatarState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('energy')) {
      context.handle(
        _energyMeta,
        energy.isAcceptableOrUnknown(data['energy']!, _energyMeta),
      );
    } else if (isInserting) {
      context.missing(_energyMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    } else if (isInserting) {
      context.missing(_moodMeta);
    }
    if (data.containsKey('curiosity')) {
      context.handle(
        _curiosityMeta,
        curiosity.isAcceptableOrUnknown(data['curiosity']!, _curiosityMeta),
      );
    } else if (isInserting) {
      context.missing(_curiosityMeta);
    }
    if (data.containsKey('rapport')) {
      context.handle(
        _rapportMeta,
        rapport.isAcceptableOrUnknown(data['rapport']!, _rapportMeta),
      );
    } else if (isInserting) {
      context.missing(_rapportMeta);
    }
    if (data.containsKey('affection')) {
      context.handle(
        _affectionMeta,
        affection.isAcceptableOrUnknown(data['affection']!, _affectionMeta),
      );
    } else if (isInserting) {
      context.missing(_affectionMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AvatarState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AvatarState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      energy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}energy'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      )!,
      curiosity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}curiosity'],
      )!,
      rapport: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rapport'],
      )!,
      affection: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}affection'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AvatarStatesTable createAlias(String alias) {
    return $AvatarStatesTable(attachedDatabase, alias);
  }
}

class AvatarState extends DataClass implements Insertable<AvatarState> {
  final String id;
  final int energy;
  final String mood;
  final int curiosity;
  final int rapport;
  final int affection;
  final DateTime updatedAt;
  const AvatarState({
    required this.id,
    required this.energy,
    required this.mood,
    required this.curiosity,
    required this.rapport,
    required this.affection,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['energy'] = Variable<int>(energy);
    map['mood'] = Variable<String>(mood);
    map['curiosity'] = Variable<int>(curiosity);
    map['rapport'] = Variable<int>(rapport);
    map['affection'] = Variable<int>(affection);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AvatarStatesCompanion toCompanion(bool nullToAbsent) {
    return AvatarStatesCompanion(
      id: Value(id),
      energy: Value(energy),
      mood: Value(mood),
      curiosity: Value(curiosity),
      rapport: Value(rapport),
      affection: Value(affection),
      updatedAt: Value(updatedAt),
    );
  }

  factory AvatarState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AvatarState(
      id: serializer.fromJson<String>(json['id']),
      energy: serializer.fromJson<int>(json['energy']),
      mood: serializer.fromJson<String>(json['mood']),
      curiosity: serializer.fromJson<int>(json['curiosity']),
      rapport: serializer.fromJson<int>(json['rapport']),
      affection: serializer.fromJson<int>(json['affection']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'energy': serializer.toJson<int>(energy),
      'mood': serializer.toJson<String>(mood),
      'curiosity': serializer.toJson<int>(curiosity),
      'rapport': serializer.toJson<int>(rapport),
      'affection': serializer.toJson<int>(affection),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AvatarState copyWith({
    String? id,
    int? energy,
    String? mood,
    int? curiosity,
    int? rapport,
    int? affection,
    DateTime? updatedAt,
  }) => AvatarState(
    id: id ?? this.id,
    energy: energy ?? this.energy,
    mood: mood ?? this.mood,
    curiosity: curiosity ?? this.curiosity,
    rapport: rapport ?? this.rapport,
    affection: affection ?? this.affection,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AvatarState copyWithCompanion(AvatarStatesCompanion data) {
    return AvatarState(
      id: data.id.present ? data.id.value : this.id,
      energy: data.energy.present ? data.energy.value : this.energy,
      mood: data.mood.present ? data.mood.value : this.mood,
      curiosity: data.curiosity.present ? data.curiosity.value : this.curiosity,
      rapport: data.rapport.present ? data.rapport.value : this.rapport,
      affection: data.affection.present ? data.affection.value : this.affection,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AvatarState(')
          ..write('id: $id, ')
          ..write('energy: $energy, ')
          ..write('mood: $mood, ')
          ..write('curiosity: $curiosity, ')
          ..write('rapport: $rapport, ')
          ..write('affection: $affection, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, energy, mood, curiosity, rapport, affection, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AvatarState &&
          other.id == this.id &&
          other.energy == this.energy &&
          other.mood == this.mood &&
          other.curiosity == this.curiosity &&
          other.rapport == this.rapport &&
          other.affection == this.affection &&
          other.updatedAt == this.updatedAt);
}

class AvatarStatesCompanion extends UpdateCompanion<AvatarState> {
  final Value<String> id;
  final Value<int> energy;
  final Value<String> mood;
  final Value<int> curiosity;
  final Value<int> rapport;
  final Value<int> affection;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AvatarStatesCompanion({
    this.id = const Value.absent(),
    this.energy = const Value.absent(),
    this.mood = const Value.absent(),
    this.curiosity = const Value.absent(),
    this.rapport = const Value.absent(),
    this.affection = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AvatarStatesCompanion.insert({
    required String id,
    required int energy,
    required String mood,
    required int curiosity,
    required int rapport,
    required int affection,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       energy = Value(energy),
       mood = Value(mood),
       curiosity = Value(curiosity),
       rapport = Value(rapport),
       affection = Value(affection);
  static Insertable<AvatarState> custom({
    Expression<String>? id,
    Expression<int>? energy,
    Expression<String>? mood,
    Expression<int>? curiosity,
    Expression<int>? rapport,
    Expression<int>? affection,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (energy != null) 'energy': energy,
      if (mood != null) 'mood': mood,
      if (curiosity != null) 'curiosity': curiosity,
      if (rapport != null) 'rapport': rapport,
      if (affection != null) 'affection': affection,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AvatarStatesCompanion copyWith({
    Value<String>? id,
    Value<int>? energy,
    Value<String>? mood,
    Value<int>? curiosity,
    Value<int>? rapport,
    Value<int>? affection,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AvatarStatesCompanion(
      id: id ?? this.id,
      energy: energy ?? this.energy,
      mood: mood ?? this.mood,
      curiosity: curiosity ?? this.curiosity,
      rapport: rapport ?? this.rapport,
      affection: affection ?? this.affection,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (energy.present) {
      map['energy'] = Variable<int>(energy.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (curiosity.present) {
      map['curiosity'] = Variable<int>(curiosity.value);
    }
    if (rapport.present) {
      map['rapport'] = Variable<int>(rapport.value);
    }
    if (affection.present) {
      map['affection'] = Variable<int>(affection.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AvatarStatesCompanion(')
          ..write('id: $id, ')
          ..write('energy: $energy, ')
          ..write('mood: $mood, ')
          ..write('curiosity: $curiosity, ')
          ..write('rapport: $rapport, ')
          ..write('affection: $affection, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerTypeMeta = const VerificationMeta(
    'triggerType',
  );
  @override
  late final GeneratedColumn<String> triggerType = GeneratedColumn<String>(
    'trigger_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cooldownMinutesMeta = const VerificationMeta(
    'cooldownMinutes',
  );
  @override
  late final GeneratedColumn<int> cooldownMinutes = GeneratedColumn<int>(
    'cooldown_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    triggerType,
    title,
    description,
    cooldownMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trigger_type')) {
      context.handle(
        _triggerTypeMeta,
        triggerType.isAcceptableOrUnknown(
          data['trigger_type']!,
          _triggerTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_triggerTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('cooldown_minutes')) {
      context.handle(
        _cooldownMinutesMeta,
        cooldownMinutes.isAcceptableOrUnknown(
          data['cooldown_minutes']!,
          _cooldownMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      triggerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      cooldownMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cooldown_minutes'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final String id;
  final String triggerType;
  final String title;
  final String description;
  final int cooldownMinutes;
  const Reminder({
    required this.id,
    required this.triggerType,
    required this.title,
    required this.description,
    required this.cooldownMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trigger_type'] = Variable<String>(triggerType);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['cooldown_minutes'] = Variable<int>(cooldownMinutes);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      triggerType: Value(triggerType),
      title: Value(title),
      description: Value(description),
      cooldownMinutes: Value(cooldownMinutes),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<String>(json['id']),
      triggerType: serializer.fromJson<String>(json['triggerType']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      cooldownMinutes: serializer.fromJson<int>(json['cooldownMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'triggerType': serializer.toJson<String>(triggerType),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'cooldownMinutes': serializer.toJson<int>(cooldownMinutes),
    };
  }

  Reminder copyWith({
    String? id,
    String? triggerType,
    String? title,
    String? description,
    int? cooldownMinutes,
  }) => Reminder(
    id: id ?? this.id,
    triggerType: triggerType ?? this.triggerType,
    title: title ?? this.title,
    description: description ?? this.description,
    cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      triggerType: data.triggerType.present
          ? data.triggerType.value
          : this.triggerType,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      cooldownMinutes: data.cooldownMinutes.present
          ? data.cooldownMinutes.value
          : this.cooldownMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('triggerType: $triggerType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('cooldownMinutes: $cooldownMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, triggerType, title, description, cooldownMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.triggerType == this.triggerType &&
          other.title == this.title &&
          other.description == this.description &&
          other.cooldownMinutes == this.cooldownMinutes);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<String> id;
  final Value<String> triggerType;
  final Value<String> title;
  final Value<String> description;
  final Value<int> cooldownMinutes;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.triggerType = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.cooldownMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required String triggerType,
    required String title,
    required String description,
    this.cooldownMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       triggerType = Value(triggerType),
       title = Value(title),
       description = Value(description);
  static Insertable<Reminder> custom({
    Expression<String>? id,
    Expression<String>? triggerType,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? cooldownMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (triggerType != null) 'trigger_type': triggerType,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (cooldownMinutes != null) 'cooldown_minutes': cooldownMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<String>? triggerType,
    Value<String>? title,
    Value<String>? description,
    Value<int>? cooldownMinutes,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      triggerType: triggerType ?? this.triggerType,
      title: title ?? this.title,
      description: description ?? this.description,
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (triggerType.present) {
      map['trigger_type'] = Variable<String>(triggerType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (cooldownMinutes.present) {
      map['cooldown_minutes'] = Variable<int>(cooldownMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('triggerType: $triggerType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('cooldownMinutes: $cooldownMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotoCandidatesTable extends PhotoCandidates
    with TableInfo<$PhotoCandidatesTable, PhotoCandidate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotoCandidatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, location, score, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photo_candidates';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhotoCandidate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhotoCandidate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoCandidate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
    );
  }

  @override
  $PhotoCandidatesTable createAlias(String alias) {
    return $PhotoCandidatesTable(attachedDatabase, alias);
  }
}

class PhotoCandidate extends DataClass implements Insertable<PhotoCandidate> {
  final String id;
  final String location;
  final double score;
  final String description;
  const PhotoCandidate({
    required this.id,
    required this.location,
    required this.score,
    required this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['location'] = Variable<String>(location);
    map['score'] = Variable<double>(score);
    map['description'] = Variable<String>(description);
    return map;
  }

  PhotoCandidatesCompanion toCompanion(bool nullToAbsent) {
    return PhotoCandidatesCompanion(
      id: Value(id),
      location: Value(location),
      score: Value(score),
      description: Value(description),
    );
  }

  factory PhotoCandidate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoCandidate(
      id: serializer.fromJson<String>(json['id']),
      location: serializer.fromJson<String>(json['location']),
      score: serializer.fromJson<double>(json['score']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'location': serializer.toJson<String>(location),
      'score': serializer.toJson<double>(score),
      'description': serializer.toJson<String>(description),
    };
  }

  PhotoCandidate copyWith({
    String? id,
    String? location,
    double? score,
    String? description,
  }) => PhotoCandidate(
    id: id ?? this.id,
    location: location ?? this.location,
    score: score ?? this.score,
    description: description ?? this.description,
  );
  PhotoCandidate copyWithCompanion(PhotoCandidatesCompanion data) {
    return PhotoCandidate(
      id: data.id.present ? data.id.value : this.id,
      location: data.location.present ? data.location.value : this.location,
      score: data.score.present ? data.score.value : this.score,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoCandidate(')
          ..write('id: $id, ')
          ..write('location: $location, ')
          ..write('score: $score, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, location, score, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoCandidate &&
          other.id == this.id &&
          other.location == this.location &&
          other.score == this.score &&
          other.description == this.description);
}

class PhotoCandidatesCompanion extends UpdateCompanion<PhotoCandidate> {
  final Value<String> id;
  final Value<String> location;
  final Value<double> score;
  final Value<String> description;
  final Value<int> rowid;
  const PhotoCandidatesCompanion({
    this.id = const Value.absent(),
    this.location = const Value.absent(),
    this.score = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotoCandidatesCompanion.insert({
    required String id,
    required String location,
    required double score,
    required String description,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       location = Value(location),
       score = Value(score),
       description = Value(description);
  static Insertable<PhotoCandidate> custom({
    Expression<String>? id,
    Expression<String>? location,
    Expression<double>? score,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (location != null) 'location': location,
      if (score != null) 'score': score,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotoCandidatesCompanion copyWith({
    Value<String>? id,
    Value<String>? location,
    Value<double>? score,
    Value<String>? description,
    Value<int>? rowid,
  }) {
    return PhotoCandidatesCompanion(
      id: id ?? this.id,
      location: location ?? this.location,
      score: score ?? this.score,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotoCandidatesCompanion(')
          ..write('id: $id, ')
          ..write('location: $location, ')
          ..write('score: $score, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TripReviewsTable extends TripReviews
    with TableInfo<$TripReviewsTable, TripReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewJsonMeta = const VerificationMeta(
    'reviewJson',
  );
  @override
  late final GeneratedColumn<String> reviewJson = GeneratedColumn<String>(
    'review_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, tripId, reviewJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trip_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<TripReview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('review_json')) {
      context.handle(
        _reviewJsonMeta,
        reviewJson.isAcceptableOrUnknown(data['review_json']!, _reviewJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TripReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripReview(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      reviewJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TripReviewsTable createAlias(String alias) {
    return $TripReviewsTable(attachedDatabase, alias);
  }
}

class TripReview extends DataClass implements Insertable<TripReview> {
  final String id;
  final String tripId;
  final String reviewJson;
  final DateTime createdAt;
  const TripReview({
    required this.id,
    required this.tripId,
    required this.reviewJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['review_json'] = Variable<String>(reviewJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TripReviewsCompanion toCompanion(bool nullToAbsent) {
    return TripReviewsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      reviewJson: Value(reviewJson),
      createdAt: Value(createdAt),
    );
  }

  factory TripReview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripReview(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      reviewJson: serializer.fromJson<String>(json['reviewJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tripId': serializer.toJson<String>(tripId),
      'reviewJson': serializer.toJson<String>(reviewJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TripReview copyWith({
    String? id,
    String? tripId,
    String? reviewJson,
    DateTime? createdAt,
  }) => TripReview(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    reviewJson: reviewJson ?? this.reviewJson,
    createdAt: createdAt ?? this.createdAt,
  );
  TripReview copyWithCompanion(TripReviewsCompanion data) {
    return TripReview(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      reviewJson: data.reviewJson.present
          ? data.reviewJson.value
          : this.reviewJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripReview(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('reviewJson: $reviewJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tripId, reviewJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripReview &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.reviewJson == this.reviewJson &&
          other.createdAt == this.createdAt);
}

class TripReviewsCompanion extends UpdateCompanion<TripReview> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<String> reviewJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TripReviewsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.reviewJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TripReviewsCompanion.insert({
    required String id,
    required String tripId,
    required String reviewJson,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       reviewJson = Value(reviewJson);
  static Insertable<TripReview> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<String>? reviewJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (reviewJson != null) 'review_json': reviewJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TripReviewsCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<String>? reviewJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TripReviewsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      reviewJson: reviewJson ?? this.reviewJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (reviewJson.present) {
      map['review_json'] = Variable<String>(reviewJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripReviewsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('reviewJson: $reviewJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSyncOperationsTable extends LocalSyncOperations
    with TableInfo<$LocalSyncOperationsTable, LocalSyncOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    operation,
    payloadJson,
    status,
    attemptCount,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSyncOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSyncOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalSyncOperationsTable createAlias(String alias) {
    return $LocalSyncOperationsTable(attachedDatabase, alias);
  }
}

class LocalSyncOperation extends DataClass
    implements Insertable<LocalSyncOperation> {
  final String id;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final String status;
  final int attemptCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalSyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.status,
    required this.attemptCount,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalSyncOperationsCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncOperationsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      status: Value(status),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalSyncOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncOperation(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalSyncOperation copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? operation,
    String? payloadJson,
    String? status,
    int? attemptCount,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalSyncOperation(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalSyncOperation copyWithCompanion(LocalSyncOperationsCompanion data) {
    return LocalSyncOperation(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncOperation(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operation,
    payloadJson,
    status,
    attemptCount,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncOperation &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalSyncOperationsCompanion extends UpdateCompanion<LocalSyncOperation> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalSyncOperationsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncOperationsCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payloadJson = Value(payloadJson);
  static Insertable<LocalSyncOperation> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncOperationsCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<int>? attemptCount,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalSyncOperationsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncOperationsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalUsersTable localUsers = $LocalUsersTable(this);
  late final $MemoryCapsulesTable memoryCapsules = $MemoryCapsulesTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $TripContextsTable tripContexts = $TripContextsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $ChatSummariesTable chatSummaries = $ChatSummariesTable(this);
  late final $AvatarStatesTable avatarStates = $AvatarStatesTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $PhotoCandidatesTable photoCandidates = $PhotoCandidatesTable(
    this,
  );
  late final $TripReviewsTable tripReviews = $TripReviewsTable(this);
  late final $LocalSyncOperationsTable localSyncOperations =
      $LocalSyncOperationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localUsers,
    memoryCapsules,
    userProfiles,
    tripContexts,
    chatMessages,
    chatSummaries,
    avatarStates,
    reminders,
    photoCandidates,
    tripReviews,
    localSyncOperations,
  ];
}

typedef $$LocalUsersTableCreateCompanionBuilder =
    LocalUsersCompanion Function({
      required String id,
      required String displayName,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$LocalUsersTableUpdateCompanionBuilder =
    LocalUsersCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalUsersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalUsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalUsersTable,
          LocalUser,
          $$LocalUsersTableFilterComposer,
          $$LocalUsersTableOrderingComposer,
          $$LocalUsersTableAnnotationComposer,
          $$LocalUsersTableCreateCompanionBuilder,
          $$LocalUsersTableUpdateCompanionBuilder,
          (
            LocalUser,
            BaseReferences<_$AppDatabase, $LocalUsersTable, LocalUser>,
          ),
          LocalUser,
          PrefetchHooks Function()
        > {
  $$LocalUsersTableTableManager(_$AppDatabase db, $LocalUsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUsersCompanion(
                id: id,
                displayName: displayName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUsersCompanion.insert(
                id: id,
                displayName: displayName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalUsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalUsersTable,
      LocalUser,
      $$LocalUsersTableFilterComposer,
      $$LocalUsersTableOrderingComposer,
      $$LocalUsersTableAnnotationComposer,
      $$LocalUsersTableCreateCompanionBuilder,
      $$LocalUsersTableUpdateCompanionBuilder,
      (LocalUser, BaseReferences<_$AppDatabase, $LocalUsersTable, LocalUser>),
      LocalUser,
      PrefetchHooks Function()
    >;
typedef $$MemoryCapsulesTableCreateCompanionBuilder =
    MemoryCapsulesCompanion Function({
      required String id,
      required String title,
      required String content,
      required String scope,
      Value<String> source,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$MemoryCapsulesTableUpdateCompanionBuilder =
    MemoryCapsulesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> content,
      Value<String> scope,
      Value<String> source,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$MemoryCapsulesTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryCapsulesTable> {
  $$MemoryCapsulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoryCapsulesTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryCapsulesTable> {
  $$MemoryCapsulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoryCapsulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryCapsulesTable> {
  $$MemoryCapsulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MemoryCapsulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemoryCapsulesTable,
          MemoryCapsule,
          $$MemoryCapsulesTableFilterComposer,
          $$MemoryCapsulesTableOrderingComposer,
          $$MemoryCapsulesTableAnnotationComposer,
          $$MemoryCapsulesTableCreateCompanionBuilder,
          $$MemoryCapsulesTableUpdateCompanionBuilder,
          (
            MemoryCapsule,
            BaseReferences<_$AppDatabase, $MemoryCapsulesTable, MemoryCapsule>,
          ),
          MemoryCapsule,
          PrefetchHooks Function()
        > {
  $$MemoryCapsulesTableTableManager(
    _$AppDatabase db,
    $MemoryCapsulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryCapsulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryCapsulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryCapsulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryCapsulesCompanion(
                id: id,
                title: title,
                content: content,
                scope: scope,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String content,
                required String scope,
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryCapsulesCompanion.insert(
                id: id,
                title: title,
                content: content,
                scope: scope,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoryCapsulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemoryCapsulesTable,
      MemoryCapsule,
      $$MemoryCapsulesTableFilterComposer,
      $$MemoryCapsulesTableOrderingComposer,
      $$MemoryCapsulesTableAnnotationComposer,
      $$MemoryCapsulesTableCreateCompanionBuilder,
      $$MemoryCapsulesTableUpdateCompanionBuilder,
      (
        MemoryCapsule,
        BaseReferences<_$AppDatabase, $MemoryCapsulesTable, MemoryCapsule>,
      ),
      MemoryCapsule,
      PrefetchHooks Function()
    >;
typedef $$UserProfilesTableCreateCompanionBuilder =
    UserProfilesCompanion Function({
      required String id,
      required String userId,
      required String profileJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UserProfilesTableUpdateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> profileJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfilesTable,
          UserProfile,
          $$UserProfilesTableFilterComposer,
          $$UserProfilesTableOrderingComposer,
          $$UserProfilesTableAnnotationComposer,
          $$UserProfilesTableCreateCompanionBuilder,
          $$UserProfilesTableUpdateCompanionBuilder,
          (
            UserProfile,
            BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>,
          ),
          UserProfile,
          PrefetchHooks Function()
        > {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> profileJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfilesCompanion(
                id: id,
                userId: userId,
                profileJson: profileJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String profileJson,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfilesCompanion.insert(
                id: id,
                userId: userId,
                profileJson: profileJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfilesTable,
      UserProfile,
      $$UserProfilesTableFilterComposer,
      $$UserProfilesTableOrderingComposer,
      $$UserProfilesTableAnnotationComposer,
      $$UserProfilesTableCreateCompanionBuilder,
      $$UserProfilesTableUpdateCompanionBuilder,
      (
        UserProfile,
        BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>,
      ),
      UserProfile,
      PrefetchHooks Function()
    >;
typedef $$TripContextsTableCreateCompanionBuilder =
    TripContextsCompanion Function({
      required String id,
      required String userId,
      required String destination,
      required String contextJson,
      Value<int> rowid,
    });
typedef $$TripContextsTableUpdateCompanionBuilder =
    TripContextsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> destination,
      Value<String> contextJson,
      Value<int> rowid,
    });

class $$TripContextsTableFilterComposer
    extends Composer<_$AppDatabase, $TripContextsTable> {
  $$TripContextsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TripContextsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripContextsTable> {
  $$TripContextsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripContextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripContextsTable> {
  $$TripContextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => column,
  );
}

class $$TripContextsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripContextsTable,
          TripContext,
          $$TripContextsTableFilterComposer,
          $$TripContextsTableOrderingComposer,
          $$TripContextsTableAnnotationComposer,
          $$TripContextsTableCreateCompanionBuilder,
          $$TripContextsTableUpdateCompanionBuilder,
          (
            TripContext,
            BaseReferences<_$AppDatabase, $TripContextsTable, TripContext>,
          ),
          TripContext,
          PrefetchHooks Function()
        > {
  $$TripContextsTableTableManager(_$AppDatabase db, $TripContextsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripContextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripContextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripContextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> destination = const Value.absent(),
                Value<String> contextJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripContextsCompanion(
                id: id,
                userId: userId,
                destination: destination,
                contextJson: contextJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String destination,
                required String contextJson,
                Value<int> rowid = const Value.absent(),
              }) => TripContextsCompanion.insert(
                id: id,
                userId: userId,
                destination: destination,
                contextJson: contextJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TripContextsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripContextsTable,
      TripContext,
      $$TripContextsTableFilterComposer,
      $$TripContextsTableOrderingComposer,
      $$TripContextsTableAnnotationComposer,
      $$TripContextsTableCreateCompanionBuilder,
      $$TripContextsTableUpdateCompanionBuilder,
      (
        TripContext,
        BaseReferences<_$AppDatabase, $TripContextsTable, TripContext>,
      ),
      TripContext,
      PrefetchHooks Function()
    >;
typedef $$ChatMessagesTableCreateCompanionBuilder =
    ChatMessagesCompanion Function({
      required String id,
      required String sessionId,
      required String sender,
      required String body,
      Value<String?> avatarState,
      Value<String?> cardPayload,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ChatMessagesTableUpdateCompanionBuilder =
    ChatMessagesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> sender,
      Value<String> body,
      Value<String?> avatarState,
      Value<String?> cardPayload,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarState => $composableBuilder(
    column: $table.avatarState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardPayload => $composableBuilder(
    column: $table.cardPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarState => $composableBuilder(
    column: $table.avatarState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardPayload => $composableBuilder(
    column: $table.cardPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get avatarState => $composableBuilder(
    column: $table.avatarState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardPayload => $composableBuilder(
    column: $table.cardPayload,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ChatMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatMessagesTable,
          ChatMessage,
          $$ChatMessagesTableFilterComposer,
          $$ChatMessagesTableOrderingComposer,
          $$ChatMessagesTableAnnotationComposer,
          $$ChatMessagesTableCreateCompanionBuilder,
          $$ChatMessagesTableUpdateCompanionBuilder,
          (
            ChatMessage,
            BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage>,
          ),
          ChatMessage,
          PrefetchHooks Function()
        > {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> avatarState = const Value.absent(),
                Value<String?> cardPayload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion(
                id: id,
                sessionId: sessionId,
                sender: sender,
                body: body,
                avatarState: avatarState,
                cardPayload: cardPayload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String sender,
                required String body,
                Value<String?> avatarState = const Value.absent(),
                Value<String?> cardPayload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion.insert(
                id: id,
                sessionId: sessionId,
                sender: sender,
                body: body,
                avatarState: avatarState,
                cardPayload: cardPayload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatMessagesTable,
      ChatMessage,
      $$ChatMessagesTableFilterComposer,
      $$ChatMessagesTableOrderingComposer,
      $$ChatMessagesTableAnnotationComposer,
      $$ChatMessagesTableCreateCompanionBuilder,
      $$ChatMessagesTableUpdateCompanionBuilder,
      (
        ChatMessage,
        BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage>,
      ),
      ChatMessage,
      PrefetchHooks Function()
    >;
typedef $$ChatSummariesTableCreateCompanionBuilder =
    ChatSummariesCompanion Function({
      required String id,
      required String sessionId,
      required String summary,
      Value<int> rowid,
    });
typedef $$ChatSummariesTableUpdateCompanionBuilder =
    ChatSummariesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> summary,
      Value<int> rowid,
    });

class $$ChatSummariesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatSummariesTable> {
  $$ChatSummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatSummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatSummariesTable> {
  $$ChatSummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatSummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatSummariesTable> {
  $$ChatSummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);
}

class $$ChatSummariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatSummariesTable,
          ChatSummary,
          $$ChatSummariesTableFilterComposer,
          $$ChatSummariesTableOrderingComposer,
          $$ChatSummariesTableAnnotationComposer,
          $$ChatSummariesTableCreateCompanionBuilder,
          $$ChatSummariesTableUpdateCompanionBuilder,
          (
            ChatSummary,
            BaseReferences<_$AppDatabase, $ChatSummariesTable, ChatSummary>,
          ),
          ChatSummary,
          PrefetchHooks Function()
        > {
  $$ChatSummariesTableTableManager(_$AppDatabase db, $ChatSummariesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatSummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatSummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatSummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatSummariesCompanion(
                id: id,
                sessionId: sessionId,
                summary: summary,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String summary,
                Value<int> rowid = const Value.absent(),
              }) => ChatSummariesCompanion.insert(
                id: id,
                sessionId: sessionId,
                summary: summary,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatSummariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatSummariesTable,
      ChatSummary,
      $$ChatSummariesTableFilterComposer,
      $$ChatSummariesTableOrderingComposer,
      $$ChatSummariesTableAnnotationComposer,
      $$ChatSummariesTableCreateCompanionBuilder,
      $$ChatSummariesTableUpdateCompanionBuilder,
      (
        ChatSummary,
        BaseReferences<_$AppDatabase, $ChatSummariesTable, ChatSummary>,
      ),
      ChatSummary,
      PrefetchHooks Function()
    >;
typedef $$AvatarStatesTableCreateCompanionBuilder =
    AvatarStatesCompanion Function({
      required String id,
      required int energy,
      required String mood,
      required int curiosity,
      required int rapport,
      required int affection,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AvatarStatesTableUpdateCompanionBuilder =
    AvatarStatesCompanion Function({
      Value<String> id,
      Value<int> energy,
      Value<String> mood,
      Value<int> curiosity,
      Value<int> rapport,
      Value<int> affection,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AvatarStatesTableFilterComposer
    extends Composer<_$AppDatabase, $AvatarStatesTable> {
  $$AvatarStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get energy => $composableBuilder(
    column: $table.energy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get curiosity => $composableBuilder(
    column: $table.curiosity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rapport => $composableBuilder(
    column: $table.rapport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get affection => $composableBuilder(
    column: $table.affection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AvatarStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $AvatarStatesTable> {
  $$AvatarStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get energy => $composableBuilder(
    column: $table.energy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get curiosity => $composableBuilder(
    column: $table.curiosity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rapport => $composableBuilder(
    column: $table.rapport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get affection => $composableBuilder(
    column: $table.affection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AvatarStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AvatarStatesTable> {
  $$AvatarStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get energy =>
      $composableBuilder(column: $table.energy, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<int> get curiosity =>
      $composableBuilder(column: $table.curiosity, builder: (column) => column);

  GeneratedColumn<int> get rapport =>
      $composableBuilder(column: $table.rapport, builder: (column) => column);

  GeneratedColumn<int> get affection =>
      $composableBuilder(column: $table.affection, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AvatarStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AvatarStatesTable,
          AvatarState,
          $$AvatarStatesTableFilterComposer,
          $$AvatarStatesTableOrderingComposer,
          $$AvatarStatesTableAnnotationComposer,
          $$AvatarStatesTableCreateCompanionBuilder,
          $$AvatarStatesTableUpdateCompanionBuilder,
          (
            AvatarState,
            BaseReferences<_$AppDatabase, $AvatarStatesTable, AvatarState>,
          ),
          AvatarState,
          PrefetchHooks Function()
        > {
  $$AvatarStatesTableTableManager(_$AppDatabase db, $AvatarStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AvatarStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AvatarStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AvatarStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> energy = const Value.absent(),
                Value<String> mood = const Value.absent(),
                Value<int> curiosity = const Value.absent(),
                Value<int> rapport = const Value.absent(),
                Value<int> affection = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AvatarStatesCompanion(
                id: id,
                energy: energy,
                mood: mood,
                curiosity: curiosity,
                rapport: rapport,
                affection: affection,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int energy,
                required String mood,
                required int curiosity,
                required int rapport,
                required int affection,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AvatarStatesCompanion.insert(
                id: id,
                energy: energy,
                mood: mood,
                curiosity: curiosity,
                rapport: rapport,
                affection: affection,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AvatarStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AvatarStatesTable,
      AvatarState,
      $$AvatarStatesTableFilterComposer,
      $$AvatarStatesTableOrderingComposer,
      $$AvatarStatesTableAnnotationComposer,
      $$AvatarStatesTableCreateCompanionBuilder,
      $$AvatarStatesTableUpdateCompanionBuilder,
      (
        AvatarState,
        BaseReferences<_$AppDatabase, $AvatarStatesTable, AvatarState>,
      ),
      AvatarState,
      PrefetchHooks Function()
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      required String id,
      required String triggerType,
      required String title,
      required String description,
      Value<int> cooldownMinutes,
      Value<int> rowid,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<String> id,
      Value<String> triggerType,
      Value<String> title,
      Value<String> description,
      Value<int> cooldownMinutes,
      Value<int> rowid,
    });

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get triggerType => $composableBuilder(
    column: $table.triggerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cooldownMinutes => $composableBuilder(
    column: $table.cooldownMinutes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get triggerType => $composableBuilder(
    column: $table.triggerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cooldownMinutes => $composableBuilder(
    column: $table.cooldownMinutes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get triggerType => $composableBuilder(
    column: $table.triggerType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cooldownMinutes => $composableBuilder(
    column: $table.cooldownMinutes,
    builder: (column) => column,
  );
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
          Reminder,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> triggerType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> cooldownMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                triggerType: triggerType,
                title: title,
                description: description,
                cooldownMinutes: cooldownMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String triggerType,
                required String title,
                required String description,
                Value<int> cooldownMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                triggerType: triggerType,
                title: title,
                description: description,
                cooldownMinutes: cooldownMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
      Reminder,
      PrefetchHooks Function()
    >;
typedef $$PhotoCandidatesTableCreateCompanionBuilder =
    PhotoCandidatesCompanion Function({
      required String id,
      required String location,
      required double score,
      required String description,
      Value<int> rowid,
    });
typedef $$PhotoCandidatesTableUpdateCompanionBuilder =
    PhotoCandidatesCompanion Function({
      Value<String> id,
      Value<String> location,
      Value<double> score,
      Value<String> description,
      Value<int> rowid,
    });

class $$PhotoCandidatesTableFilterComposer
    extends Composer<_$AppDatabase, $PhotoCandidatesTable> {
  $$PhotoCandidatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhotoCandidatesTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotoCandidatesTable> {
  $$PhotoCandidatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhotoCandidatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotoCandidatesTable> {
  $$PhotoCandidatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$PhotoCandidatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotoCandidatesTable,
          PhotoCandidate,
          $$PhotoCandidatesTableFilterComposer,
          $$PhotoCandidatesTableOrderingComposer,
          $$PhotoCandidatesTableAnnotationComposer,
          $$PhotoCandidatesTableCreateCompanionBuilder,
          $$PhotoCandidatesTableUpdateCompanionBuilder,
          (
            PhotoCandidate,
            BaseReferences<
              _$AppDatabase,
              $PhotoCandidatesTable,
              PhotoCandidate
            >,
          ),
          PhotoCandidate,
          PrefetchHooks Function()
        > {
  $$PhotoCandidatesTableTableManager(
    _$AppDatabase db,
    $PhotoCandidatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotoCandidatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotoCandidatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotoCandidatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotoCandidatesCompanion(
                id: id,
                location: location,
                score: score,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String location,
                required double score,
                required String description,
                Value<int> rowid = const Value.absent(),
              }) => PhotoCandidatesCompanion.insert(
                id: id,
                location: location,
                score: score,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhotoCandidatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotoCandidatesTable,
      PhotoCandidate,
      $$PhotoCandidatesTableFilterComposer,
      $$PhotoCandidatesTableOrderingComposer,
      $$PhotoCandidatesTableAnnotationComposer,
      $$PhotoCandidatesTableCreateCompanionBuilder,
      $$PhotoCandidatesTableUpdateCompanionBuilder,
      (
        PhotoCandidate,
        BaseReferences<_$AppDatabase, $PhotoCandidatesTable, PhotoCandidate>,
      ),
      PhotoCandidate,
      PrefetchHooks Function()
    >;
typedef $$TripReviewsTableCreateCompanionBuilder =
    TripReviewsCompanion Function({
      required String id,
      required String tripId,
      required String reviewJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$TripReviewsTableUpdateCompanionBuilder =
    TripReviewsCompanion Function({
      Value<String> id,
      Value<String> tripId,
      Value<String> reviewJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$TripReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $TripReviewsTable> {
  $$TripReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewJson => $composableBuilder(
    column: $table.reviewJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TripReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripReviewsTable> {
  $$TripReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewJson => $composableBuilder(
    column: $table.reviewJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripReviewsTable> {
  $$TripReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get reviewJson => $composableBuilder(
    column: $table.reviewJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TripReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripReviewsTable,
          TripReview,
          $$TripReviewsTableFilterComposer,
          $$TripReviewsTableOrderingComposer,
          $$TripReviewsTableAnnotationComposer,
          $$TripReviewsTableCreateCompanionBuilder,
          $$TripReviewsTableUpdateCompanionBuilder,
          (
            TripReview,
            BaseReferences<_$AppDatabase, $TripReviewsTable, TripReview>,
          ),
          TripReview,
          PrefetchHooks Function()
        > {
  $$TripReviewsTableTableManager(_$AppDatabase db, $TripReviewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<String> reviewJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripReviewsCompanion(
                id: id,
                tripId: tripId,
                reviewJson: reviewJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tripId,
                required String reviewJson,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripReviewsCompanion.insert(
                id: id,
                tripId: tripId,
                reviewJson: reviewJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TripReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripReviewsTable,
      TripReview,
      $$TripReviewsTableFilterComposer,
      $$TripReviewsTableOrderingComposer,
      $$TripReviewsTableAnnotationComposer,
      $$TripReviewsTableCreateCompanionBuilder,
      $$TripReviewsTableUpdateCompanionBuilder,
      (
        TripReview,
        BaseReferences<_$AppDatabase, $TripReviewsTable, TripReview>,
      ),
      TripReview,
      PrefetchHooks Function()
    >;
typedef $$LocalSyncOperationsTableCreateCompanionBuilder =
    LocalSyncOperationsCompanion Function({
      required String id,
      required String entityType,
      required String entityId,
      required String operation,
      required String payloadJson,
      Value<String> status,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalSyncOperationsTableUpdateCompanionBuilder =
    LocalSyncOperationsCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operation,
      Value<String> payloadJson,
      Value<String> status,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalSyncOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSyncOperationsTable> {
  $$LocalSyncOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSyncOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSyncOperationsTable> {
  $$LocalSyncOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSyncOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSyncOperationsTable> {
  $$LocalSyncOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalSyncOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSyncOperationsTable,
          LocalSyncOperation,
          $$LocalSyncOperationsTableFilterComposer,
          $$LocalSyncOperationsTableOrderingComposer,
          $$LocalSyncOperationsTableAnnotationComposer,
          $$LocalSyncOperationsTableCreateCompanionBuilder,
          $$LocalSyncOperationsTableUpdateCompanionBuilder,
          (
            LocalSyncOperation,
            BaseReferences<
              _$AppDatabase,
              $LocalSyncOperationsTable,
              LocalSyncOperation
            >,
          ),
          LocalSyncOperation,
          PrefetchHooks Function()
        > {
  $$LocalSyncOperationsTableTableManager(
    _$AppDatabase db,
    $LocalSyncOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSyncOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSyncOperationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalSyncOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncOperationsCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String operation,
                required String payloadJson,
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncOperationsCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSyncOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSyncOperationsTable,
      LocalSyncOperation,
      $$LocalSyncOperationsTableFilterComposer,
      $$LocalSyncOperationsTableOrderingComposer,
      $$LocalSyncOperationsTableAnnotationComposer,
      $$LocalSyncOperationsTableCreateCompanionBuilder,
      $$LocalSyncOperationsTableUpdateCompanionBuilder,
      (
        LocalSyncOperation,
        BaseReferences<
          _$AppDatabase,
          $LocalSyncOperationsTable,
          LocalSyncOperation
        >,
      ),
      LocalSyncOperation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalUsersTableTableManager get localUsers =>
      $$LocalUsersTableTableManager(_db, _db.localUsers);
  $$MemoryCapsulesTableTableManager get memoryCapsules =>
      $$MemoryCapsulesTableTableManager(_db, _db.memoryCapsules);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$TripContextsTableTableManager get tripContexts =>
      $$TripContextsTableTableManager(_db, _db.tripContexts);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$ChatSummariesTableTableManager get chatSummaries =>
      $$ChatSummariesTableTableManager(_db, _db.chatSummaries);
  $$AvatarStatesTableTableManager get avatarStates =>
      $$AvatarStatesTableTableManager(_db, _db.avatarStates);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$PhotoCandidatesTableTableManager get photoCandidates =>
      $$PhotoCandidatesTableTableManager(_db, _db.photoCandidates);
  $$TripReviewsTableTableManager get tripReviews =>
      $$TripReviewsTableTableManager(_db, _db.tripReviews);
  $$LocalSyncOperationsTableTableManager get localSyncOperations =>
      $$LocalSyncOperationsTableTableManager(_db, _db.localSyncOperations);
}
