import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../features/cards/domain/wallet_card.dart';

/// Large payment card — layout inspired by `ui_design/wallet.png`.
class WalletCardWidget extends StatelessWidget {
  const WalletCardWidget({super.key, required this.card, this.onTap});

  final WalletCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              card.startColor,
              Color.lerp(card.startColor, card.endColor, 0.55)!,
              card.endColor,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: card.startColor.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 14),
              spreadRadius: -4,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand + wallet name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mastercard-style double circle
                SizedBox(
                  width: 40,
                  height: 28,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    card.issuerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Balance
            Text(
              CurrencyFormatter.format(card.balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 14),
            // Contactless · last4 · holder
            Row(
              children: [
                Icon(
                  Icons.contactless,
                  color: Colors.white.withValues(alpha: 0.75),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  '····  ${card.lastFour}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 16,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Chip
                Container(
                  width: 36,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.75),
                        Colors.white.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                card.holderName,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact card preview for lists / chips.
class WalletCardChip extends StatelessWidget {
  const WalletCardChip({super.key, required this.card, this.selected = false});

  final WalletCard card;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            card.startColor.withValues(alpha: selected ? 1 : 0.7),
            card.endColor.withValues(alpha: selected ? 1 : 0.7),
          ],
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: card.startColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.credit_card, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            card.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
