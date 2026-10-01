// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MonthBalancesTable extends MonthBalances
    with TableInfo<$MonthBalancesTable, MonthBalanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthBalancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<DateTime> month = GeneratedColumn<DateTime>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [month, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'month_balances';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthBalanceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {month};
  @override
  MonthBalanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthBalanceRow(
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}month'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
    );
  }

  @override
  $MonthBalancesTable createAlias(String alias) {
    return $MonthBalancesTable(attachedDatabase, alias);
  }
}

class MonthBalanceRow extends DataClass implements Insertable<MonthBalanceRow> {
  final DateTime month;
  final int amount;
  const MonthBalanceRow({required this.month, required this.amount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month'] = Variable<DateTime>(month);
    map['amount'] = Variable<int>(amount);
    return map;
  }

  MonthBalancesCompanion toCompanion(bool nullToAbsent) {
    return MonthBalancesCompanion(month: Value(month), amount: Value(amount));
  }

  factory MonthBalanceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthBalanceRow(
      month: serializer.fromJson<DateTime>(json['month']),
      amount: serializer.fromJson<int>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'month': serializer.toJson<DateTime>(month),
      'amount': serializer.toJson<int>(amount),
    };
  }

  MonthBalanceRow copyWith({DateTime? month, int? amount}) => MonthBalanceRow(
    month: month ?? this.month,
    amount: amount ?? this.amount,
  );
  MonthBalanceRow copyWithCompanion(MonthBalancesCompanion data) {
    return MonthBalanceRow(
      month: data.month.present ? data.month.value : this.month,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthBalanceRow(')
          ..write('month: $month, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(month, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthBalanceRow &&
          other.month == this.month &&
          other.amount == this.amount);
}

class MonthBalancesCompanion extends UpdateCompanion<MonthBalanceRow> {
  final Value<DateTime> month;
  final Value<int> amount;
  final Value<int> rowid;
  const MonthBalancesCompanion({
    this.month = const Value.absent(),
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthBalancesCompanion.insert({
    required DateTime month,
    required int amount,
    this.rowid = const Value.absent(),
  }) : month = Value(month),
       amount = Value(amount);
  static Insertable<MonthBalanceRow> custom({
    Expression<DateTime>? month,
    Expression<int>? amount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (month != null) 'month': month,
      if (amount != null) 'amount': amount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthBalancesCompanion copyWith({
    Value<DateTime>? month,
    Value<int>? amount,
    Value<int>? rowid,
  }) {
    return MonthBalancesCompanion(
      month: month ?? this.month,
      amount: amount ?? this.amount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (month.present) {
      map['month'] = Variable<DateTime>(month.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthBalancesCompanion(')
          ..write('month: $month, ')
          ..write('amount: $amount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PocketsTable extends Pockets with TableInfo<$PocketsTable, PocketRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PocketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _budgetMeta = const VerificationMeta('budget');
  @override
  late final GeneratedColumn<int> budget = GeneratedColumn<int>(
    'budget',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spentMeta = const VerificationMeta('spent');
  @override
  late final GeneratedColumn<int> spent = GeneratedColumn<int>(
    'spent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    emoji,
    name,
    budget,
    spent,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pockets';
  @override
  VerificationContext validateIntegrity(
    Insertable<PocketRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('budget')) {
      context.handle(
        _budgetMeta,
        budget.isAcceptableOrUnknown(data['budget']!, _budgetMeta),
      );
    } else if (isInserting) {
      context.missing(_budgetMeta);
    }
    if (data.containsKey('spent')) {
      context.handle(
        _spentMeta,
        spent.isAcceptableOrUnknown(data['spent']!, _spentMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PocketRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PocketRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      budget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget'],
      )!,
      spent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spent'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $PocketsTable createAlias(String alias) {
    return $PocketsTable(attachedDatabase, alias);
  }
}

class PocketRow extends DataClass implements Insertable<PocketRow> {
  final int id;
  final String emoji;
  final String name;
  final int budget;
  final int spent;
  final int sortOrder;
  const PocketRow({
    required this.id,
    required this.emoji,
    required this.name,
    required this.budget,
    required this.spent,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['emoji'] = Variable<String>(emoji);
    map['name'] = Variable<String>(name);
    map['budget'] = Variable<int>(budget);
    map['spent'] = Variable<int>(spent);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  PocketsCompanion toCompanion(bool nullToAbsent) {
    return PocketsCompanion(
      id: Value(id),
      emoji: Value(emoji),
      name: Value(name),
      budget: Value(budget),
      spent: Value(spent),
      sortOrder: Value(sortOrder),
    );
  }

  factory PocketRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PocketRow(
      id: serializer.fromJson<int>(json['id']),
      emoji: serializer.fromJson<String>(json['emoji']),
      name: serializer.fromJson<String>(json['name']),
      budget: serializer.fromJson<int>(json['budget']),
      spent: serializer.fromJson<int>(json['spent']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'emoji': serializer.toJson<String>(emoji),
      'name': serializer.toJson<String>(name),
      'budget': serializer.toJson<int>(budget),
      'spent': serializer.toJson<int>(spent),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  PocketRow copyWith({
    int? id,
    String? emoji,
    String? name,
    int? budget,
    int? spent,
    int? sortOrder,
  }) => PocketRow(
    id: id ?? this.id,
    emoji: emoji ?? this.emoji,
    name: name ?? this.name,
    budget: budget ?? this.budget,
    spent: spent ?? this.spent,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  PocketRow copyWithCompanion(PocketsCompanion data) {
    return PocketRow(
      id: data.id.present ? data.id.value : this.id,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      name: data.name.present ? data.name.value : this.name,
      budget: data.budget.present ? data.budget.value : this.budget,
      spent: data.spent.present ? data.spent.value : this.spent,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PocketRow(')
          ..write('id: $id, ')
          ..write('emoji: $emoji, ')
          ..write('name: $name, ')
          ..write('budget: $budget, ')
          ..write('spent: $spent, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, emoji, name, budget, spent, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PocketRow &&
          other.id == this.id &&
          other.emoji == this.emoji &&
          other.name == this.name &&
          other.budget == this.budget &&
          other.spent == this.spent &&
          other.sortOrder == this.sortOrder);
}

class PocketsCompanion extends UpdateCompanion<PocketRow> {
  final Value<int> id;
  final Value<String> emoji;
  final Value<String> name;
  final Value<int> budget;
  final Value<int> spent;
  final Value<int> sortOrder;
  const PocketsCompanion({
    this.id = const Value.absent(),
    this.emoji = const Value.absent(),
    this.name = const Value.absent(),
    this.budget = const Value.absent(),
    this.spent = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  PocketsCompanion.insert({
    this.id = const Value.absent(),
    required String emoji,
    required String name,
    required int budget,
    this.spent = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : emoji = Value(emoji),
       name = Value(name),
       budget = Value(budget);
  static Insertable<PocketRow> custom({
    Expression<int>? id,
    Expression<String>? emoji,
    Expression<String>? name,
    Expression<int>? budget,
    Expression<int>? spent,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (emoji != null) 'emoji': emoji,
      if (name != null) 'name': name,
      if (budget != null) 'budget': budget,
      if (spent != null) 'spent': spent,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  PocketsCompanion copyWith({
    Value<int>? id,
    Value<String>? emoji,
    Value<String>? name,
    Value<int>? budget,
    Value<int>? spent,
    Value<int>? sortOrder,
  }) {
    return PocketsCompanion(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      name: name ?? this.name,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (budget.present) {
      map['budget'] = Variable<int>(budget.value);
    }
    if (spent.present) {
      map['spent'] = Variable<int>(spent.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PocketsCompanion(')
          ..write('id: $id, ')
          ..write('emoji: $emoji, ')
          ..write('name: $name, ')
          ..write('budget: $budget, ')
          ..write('spent: $spent, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placeMeta = const VerificationMeta('place');
  @override
  late final GeneratedColumn<String> place = GeneratedColumn<String>(
    'place',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    emoji,
    category,
    place,
    at,
    amount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('place')) {
      context.handle(
        _placeMeta,
        place.isAcceptableOrUnknown(data['place']!, _placeMeta),
      );
    } else if (isInserting) {
      context.missing(_placeMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      place: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;
  final String emoji;
  final String category;
  final String place;
  final DateTime at;
  final int amount;
  const TransactionRow({
    required this.id,
    required this.emoji,
    required this.category,
    required this.place,
    required this.at,
    required this.amount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['emoji'] = Variable<String>(emoji);
    map['category'] = Variable<String>(category);
    map['place'] = Variable<String>(place);
    map['at'] = Variable<DateTime>(at);
    map['amount'] = Variable<int>(amount);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      emoji: Value(emoji),
      category: Value(category),
      place: Value(place),
      at: Value(at),
      amount: Value(amount),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      emoji: serializer.fromJson<String>(json['emoji']),
      category: serializer.fromJson<String>(json['category']),
      place: serializer.fromJson<String>(json['place']),
      at: serializer.fromJson<DateTime>(json['at']),
      amount: serializer.fromJson<int>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'emoji': serializer.toJson<String>(emoji),
      'category': serializer.toJson<String>(category),
      'place': serializer.toJson<String>(place),
      'at': serializer.toJson<DateTime>(at),
      'amount': serializer.toJson<int>(amount),
    };
  }

  TransactionRow copyWith({
    int? id,
    String? emoji,
    String? category,
    String? place,
    DateTime? at,
    int? amount,
  }) => TransactionRow(
    id: id ?? this.id,
    emoji: emoji ?? this.emoji,
    category: category ?? this.category,
    place: place ?? this.place,
    at: at ?? this.at,
    amount: amount ?? this.amount,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      category: data.category.present ? data.category.value : this.category,
      place: data.place.present ? data.place.value : this.place,
      at: data.at.present ? data.at.value : this.at,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('emoji: $emoji, ')
          ..write('category: $category, ')
          ..write('place: $place, ')
          ..write('at: $at, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, emoji, category, place, at, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.emoji == this.emoji &&
          other.category == this.category &&
          other.place == this.place &&
          other.at == this.at &&
          other.amount == this.amount);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<String> emoji;
  final Value<String> category;
  final Value<String> place;
  final Value<DateTime> at;
  final Value<int> amount;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.emoji = const Value.absent(),
    this.category = const Value.absent(),
    this.place = const Value.absent(),
    this.at = const Value.absent(),
    this.amount = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String emoji,
    required String category,
    required String place,
    required DateTime at,
    required int amount,
  }) : emoji = Value(emoji),
       category = Value(category),
       place = Value(place),
       at = Value(at),
       amount = Value(amount);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<String>? emoji,
    Expression<String>? category,
    Expression<String>? place,
    Expression<DateTime>? at,
    Expression<int>? amount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (emoji != null) 'emoji': emoji,
      if (category != null) 'category': category,
      if (place != null) 'place': place,
      if (at != null) 'at': at,
      if (amount != null) 'amount': amount,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<String>? emoji,
    Value<String>? category,
    Value<String>? place,
    Value<DateTime>? at,
    Value<int>? amount,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      place: place ?? this.place,
      at: at ?? this.at,
      amount: amount ?? this.amount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (place.present) {
      map['place'] = Variable<String>(place.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('emoji: $emoji, ')
          ..write('category: $category, ')
          ..write('place: $place, ')
          ..write('at: $at, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MonthBalancesTable monthBalances = $MonthBalancesTable(this);
  late final $PocketsTable pockets = $PocketsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    monthBalances,
    pockets,
    transactions,
  ];
}

typedef $$MonthBalancesTableCreateCompanionBuilder =
    MonthBalancesCompanion Function({
      required DateTime month,
      required int amount,
      Value<int> rowid,
    });
typedef $$MonthBalancesTableUpdateCompanionBuilder =
    MonthBalancesCompanion Function({
      Value<DateTime> month,
      Value<int> amount,
      Value<int> rowid,
    });

class $$MonthBalancesTableFilterComposer
    extends Composer<_$AppDatabase, $MonthBalancesTable> {
  $$MonthBalancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MonthBalancesTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthBalancesTable> {
  $$MonthBalancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MonthBalancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthBalancesTable> {
  $$MonthBalancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);
}

class $$MonthBalancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MonthBalancesTable,
          MonthBalanceRow,
          $$MonthBalancesTableFilterComposer,
          $$MonthBalancesTableOrderingComposer,
          $$MonthBalancesTableAnnotationComposer,
          $$MonthBalancesTableCreateCompanionBuilder,
          $$MonthBalancesTableUpdateCompanionBuilder,
          (
            MonthBalanceRow,
            BaseReferences<_$AppDatabase, $MonthBalancesTable, MonthBalanceRow>,
          ),
          MonthBalanceRow,
          PrefetchHooks Function()
        > {
  $$MonthBalancesTableTableManager(_$AppDatabase db, $MonthBalancesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthBalancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthBalancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthBalancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> month = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthBalancesCompanion(
                month: month,
                amount: amount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime month,
                required int amount,
                Value<int> rowid = const Value.absent(),
              }) => MonthBalancesCompanion.insert(
                month: month,
                amount: amount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MonthBalancesTable, MonthBalanceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MonthBalancesTable,
                    MonthBalanceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MonthBalancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MonthBalancesTable,
      MonthBalanceRow,
      $$MonthBalancesTableFilterComposer,
      $$MonthBalancesTableOrderingComposer,
      $$MonthBalancesTableAnnotationComposer,
      $$MonthBalancesTableCreateCompanionBuilder,
      $$MonthBalancesTableUpdateCompanionBuilder,
      (
        MonthBalanceRow,
        BaseReferences<_$AppDatabase, $MonthBalancesTable, MonthBalanceRow>,
      ),
      MonthBalanceRow,
      PrefetchHooks Function()
    >;
typedef $$PocketsTableCreateCompanionBuilder = PocketsCompanion Function({
  Value<int> id,
  required String emoji,
  required String name,
  required int budget,
  Value<int> spent,
  Value<int> sortOrder,
});
typedef $$PocketsTableUpdateCompanionBuilder = PocketsCompanion Function({
  Value<int> id,
  Value<String> emoji,
  Value<String> name,
  Value<int> budget,
  Value<int> spent,
  Value<int> sortOrder,
});

class $$PocketsTableFilterComposer
    extends Composer<_$AppDatabase, $PocketsTable> {
  $$PocketsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spent => $composableBuilder(
    column: $table.spent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PocketsTableOrderingComposer
    extends Composer<_$AppDatabase, $PocketsTable> {
  $$PocketsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spent => $composableBuilder(
    column: $table.spent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PocketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PocketsTable> {
  $$PocketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get budget =>
      $composableBuilder(column: $table.budget, builder: (column) => column);

  GeneratedColumn<int> get spent =>
      $composableBuilder(column: $table.spent, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$PocketsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PocketsTable,
          PocketRow,
          $$PocketsTableFilterComposer,
          $$PocketsTableOrderingComposer,
          $$PocketsTableAnnotationComposer,
          $$PocketsTableCreateCompanionBuilder,
          $$PocketsTableUpdateCompanionBuilder,
          (PocketRow, BaseReferences<_$AppDatabase, $PocketsTable, PocketRow>),
          PocketRow,
          PrefetchHooks Function()
        > {
  $$PocketsTableTableManager(_$AppDatabase db, $PocketsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PocketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PocketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PocketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> budget = const Value.absent(),
                Value<int> spent = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => PocketsCompanion(
                id: id,
                emoji: emoji,
                name: name,
                budget: budget,
                spent: spent,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String emoji,
                required String name,
                required int budget,
                Value<int> spent = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => PocketsCompanion.insert(
                id: id,
                emoji: emoji,
                name: name,
                budget: budget,
                spent: spent,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PocketsTable, PocketRow>(table),
                  BaseReferences<_$AppDatabase, $PocketsTable, PocketRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PocketsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PocketsTable,
      PocketRow,
      $$PocketsTableFilterComposer,
      $$PocketsTableOrderingComposer,
      $$PocketsTableAnnotationComposer,
      $$PocketsTableCreateCompanionBuilder,
      $$PocketsTableUpdateCompanionBuilder,
      (PocketRow, BaseReferences<_$AppDatabase, $PocketsTable, PocketRow>),
      PocketRow,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required String emoji,
      required String category,
      required String place,
      required DateTime at,
      required int amount,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<String> emoji,
      Value<String> category,
      Value<String> place,
      Value<DateTime> at,
      Value<int> amount,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get place =>
      $composableBuilder(column: $table.place, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            TransactionRow,
            BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>,
          ),
          TransactionRow,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> place = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int> amount = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                emoji: emoji,
                category: category,
                place: place,
                at: at,
                amount: amount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String emoji,
                required String category,
                required String place,
                required DateTime at,
                required int amount,
              }) => TransactionsCompanion.insert(
                id: id,
                emoji: emoji,
                category: category,
                place: place,
                at: at,
                amount: amount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, TransactionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TransactionsTable,
                    TransactionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        TransactionRow,
        BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>,
      ),
      TransactionRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MonthBalancesTableTableManager get monthBalances =>
      $$MonthBalancesTableTableManager(_db, _db.monthBalances);
  $$PocketsTableTableManager get pockets =>
      $$PocketsTableTableManager(_db, _db.pockets);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
}
