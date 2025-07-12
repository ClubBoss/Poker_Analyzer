// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_hand.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavedHand _$SavedHandFromJson(Map<String, dynamic> json) => SavedHand(
      name: json['name'] as String,
      spotId: json['spotId'] as String?,
      heroIndex: (json['heroIndex'] as num).toInt(),
      heroPosition: json['heroPosition'] as String,
      numberOfPlayers: (json['numberOfPlayers'] as num).toInt(),
      playerCards: (json['playerCards'] as List<dynamic>)
          .map((e) => (e as List<dynamic>)
              .map((e) => CardModel.fromJson(e as Map<String, dynamic>))
              .toList())
          .toList(),
      boardCards: (json['boardCards'] as List<dynamic>)
          .map((e) => CardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      boardStreet: (json['boardStreet'] as num).toInt(),
      revealedCards: (json['revealedCards'] as List<dynamic>?)
          ?.map((e) => (e as List<dynamic>)
              .map((e) => CardModel.fromJson(e as Map<String, dynamic>))
              .toList())
          .toList(),
      opponentIndex: (json['opponentIndex'] as num?)?.toInt(),
      activePlayerIndex: (json['activePlayerIndex'] as num?)?.toInt(),
      actions: (json['actions'] as List<dynamic>)
          .map((e) => ActionEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      stackSizes: (json['stackSizes'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
      ),
      currentBets: (json['currentBets'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
      ),
      remainingStacks: (json['remainingStacks'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
      ),
      winnings: (json['winnings'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
      ),
      totalPot: (json['totalPot'] as num?)?.toInt(),
      rake: (json['rake'] as num?)?.toInt(),
      tournamentId: json['tournamentId'] as String?,
      buyIn: (json['buyIn'] as num?)?.toInt(),
      totalPrizePool: (json['totalPrizePool'] as num?)?.toInt(),
      numberOfEntrants: (json['numberOfEntrants'] as num?)?.toInt(),
      gameType: json['gameType'] as String?,
      anteBb: (json['anteBb'] as num?)?.toInt() ?? 0,
      category: json['category'] as String?,
      playerPositions: (json['playerPositions'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(int.parse(k), e as String),
      ),
      playerTypes: (json['playerTypes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), $enumDecode(_$PlayerTypeEnumMap, e)),
      ),
      comment: json['comment'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      commentCursor: (json['commentCursor'] as num?)?.toInt(),
      tagsCursor: (json['tagsCursor'] as num?)?.toInt(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isDuplicate: json['isDuplicate'] as bool? ?? false,
      isNew: json['isNew'] as bool? ?? false,
      sessionId: (json['sessionId'] as num?)?.toInt() ?? 0,
      savedAt: json['savedAt'] == null
          ? null
          : DateTime.parse(json['savedAt'] as String),
      date:
          json['date'] == null ? null : DateTime.parse(json['date'] as String),
      expectedAction: json['expectedAction'] as String?,
      gtoAction: json['gtoAction'] as String?,
      rangeGroup: json['rangeGroup'] as String?,
      feedbackText: json['feedbackText'] as String?,
      evLoss: (json['evLoss'] as num?)?.toDouble(),
      corrected: json['corrected'] as bool? ?? false,
      evLossRecovered: (json['evLossRecovered'] as num?)?.toDouble(),
      effectiveStacksPerStreet:
          (json['effectiveStacksPerStreet'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
      validationNotes: (json['validationNotes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      collapsedHistoryStreets:
          (json['collapsedHistoryStreets'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList(),
      firstActionTaken: (json['firstActionTaken'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      foldedPlayers: (json['foldedPlayers'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      allInPlayers: (json['allInPlayers'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      actionTags: (json['actionTags'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), e as String?),
      ),
      showdownDescriptions:
          (json['showdownDescriptions'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), e as String),
      ),
      eliminatedPositions:
          (json['eliminatedPositions'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
      ),
      pendingEvaluations: (json['pendingEvaluations'] as List<dynamic>?)
          ?.map((e) =>
              ActionEvaluationRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      playbackIndex: (json['playbackIndex'] as num?)?.toInt() ?? 0,
      showFullBoard: json['showFullBoard'] as bool? ?? false,
      revealStreet: (json['revealStreet'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SavedHandToJson(SavedHand instance) => <String, dynamic>{
      'name': instance.name,
      'spotId': instance.spotId,
      'heroIndex': instance.heroIndex,
      'heroPosition': instance.heroPosition,
      'numberOfPlayers': instance.numberOfPlayers,
      'playerCards': instance.playerCards
          .map((e) => e.map((e) => e.toJson()).toList())
          .toList(),
      'boardCards': instance.boardCards.map((e) => e.toJson()).toList(),
      'revealedCards': instance.revealedCards
          .map((e) => e.map((e) => e.toJson()).toList())
          .toList(),
      'opponentIndex': instance.opponentIndex,
      'activePlayerIndex': instance.activePlayerIndex,
      'actions': instance.actions.map((e) => e.toJson()).toList(),
      'boardStreet': instance.boardStreet,
      'tournamentId': instance.tournamentId,
      'buyIn': instance.buyIn,
      'totalPrizePool': instance.totalPrizePool,
      'numberOfEntrants': instance.numberOfEntrants,
      'gameType': instance.gameType,
      'anteBb': instance.anteBb,
      'category': instance.category,
      'stackSizes':
          instance.stackSizes.map((k, e) => MapEntry(k.toString(), e)),
      'currentBets':
          instance.currentBets?.map((k, e) => MapEntry(k.toString(), e)),
      'remainingStacks':
          instance.remainingStacks?.map((k, e) => MapEntry(k.toString(), e)),
      'winnings': instance.winnings?.map((k, e) => MapEntry(k.toString(), e)),
      'totalPot': instance.totalPot,
      'rake': instance.rake,
      'playerPositions':
          instance.playerPositions.map((k, e) => MapEntry(k.toString(), e)),
      'playerTypes': instance.playerTypes
          ?.map((k, e) => MapEntry(k.toString(), _$PlayerTypeEnumMap[e]!)),
      'comment': instance.comment,
      'tags': instance.tags,
      'rating': instance.rating,
      'commentCursor': instance.commentCursor,
      'tagsCursor': instance.tagsCursor,
      'isFavorite': instance.isFavorite,
      'isDuplicate': instance.isDuplicate,
      'isNew': instance.isNew,
      'sessionId': instance.sessionId,
      'savedAt': instance.savedAt.toIso8601String(),
      'date': instance.date.toIso8601String(),
      'expectedAction': instance.expectedAction,
      'gtoAction': instance.gtoAction,
      'rangeGroup': instance.rangeGroup,
      'feedbackText': instance.feedbackText,
      'evLoss': instance.evLoss,
      'corrected': instance.corrected,
      'evLossRecovered': instance.evLossRecovered,
      'effectiveStacksPerStreet': instance.effectiveStacksPerStreet,
      'validationNotes': instance.validationNotes,
      'collapsedHistoryStreets': instance.collapsedHistoryStreets,
      'firstActionTaken': instance.firstActionTaken,
      'foldedPlayers': instance.foldedPlayers,
      'allInPlayers': instance.allInPlayers,
      'actionTags':
          instance.actionTags?.map((k, e) => MapEntry(k.toString(), e)),
      'showdownDescriptions': instance.showdownDescriptions
          ?.map((k, e) => MapEntry(k.toString(), e)),
      'eliminatedPositions': instance.eliminatedPositions
          ?.map((k, e) => MapEntry(k.toString(), e)),
      'pendingEvaluations':
          instance.pendingEvaluations?.map((e) => e.toJson()).toList(),
      'playbackIndex': instance.playbackIndex,
      'showFullBoard': instance.showFullBoard,
      'revealStreet': instance.revealStreet,
    };

const _$PlayerTypeEnumMap = {
  PlayerType.shark: 'shark',
  PlayerType.fish: 'fish',
  PlayerType.callingStation: 'callingStation',
  PlayerType.maniac: 'maniac',
  PlayerType.nit: 'nit',
  PlayerType.unknown: 'unknown',
};
