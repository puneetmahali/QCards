//
//  CardsViewModel.swift
//  QCards
//
//  Created by Andreas Lüdemann on 06/07/2019.
//  Copyright © 2019 Andreas Lüdemann. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

final class CardsViewModel: ViewModelType {
    
    struct Input {
        let trigger: Driver<Void>
        let createCardTrigger: Driver<Void>
        let deleteCardTrigger: Driver<Int>
        let editOrderTrigger: Driver<Void>
    }
    
    struct Output {
        let cards: Driver<[CardItemViewModel]>
        let editing: Driver<Bool>
        let createCard: Driver<Void>
        let deleteCard: Driver<Void>
    }
    
    private let deck: Deck
    private let useCase: CardsUseCase
    private let navigator: CardsNavigator
    
    init(deck: Deck, useCase: CardsUseCase, navigator: CardsNavigator) {
        self.deck = deck
        self.useCase = useCase
        self.navigator = navigator
    }
    
    func transform(input: Input) -> Output {
        let cards = input.trigger.flatMapLatest { _ in
            return self.useCase.cards(of: self.deck)
                .asDriverOnErrorJustComplete()
                .map { $0.map { CardItemViewModel(with: $0) }}
            }
            
            let editing = input.editOrderTrigger.scan(false) { editing, _ in
                return !editing
                }.startWith(false)
            
            let createCard = input.createCardTrigger
                .do(onNext: { self.navigator.toCreateCard(self.deck) })
        
            let deleteCard = input.deleteCardTrigger
                .withLatestFrom(cards) { row, cards in
                    return cards[row].card
                }
                .flatMapLatest { card in
                    return self.useCase.delete(card: card)
                        .asDriverOnErrorJustComplete()
            }
        
        return Output(cards: cards, editing: editing, createCard: createCard, deleteCard: deleteCard)
    }
}