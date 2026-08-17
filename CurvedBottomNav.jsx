'use client';
import React, { useState } from 'react';
import './curved-nav.css'; // Make sure to import the CSS file

// Default SVG Icons for easy plug-and-play if no icon library is installed
const HomeIcon = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
);
const WalletIcon = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="20" height="14" x="2" y="5" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/></svg>
);
const ChartIcon = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" x2="18" y1="20" y2="10"/><line x1="12" x2="12" y1="20" y2="4"/><line x1="6" x2="6" y1="20" y2="14"/></svg>
);
const UsersIcon = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
);
const InvestIcon = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/><polyline points="16 7 22 7 22 13"/></svg>
);

const DEFAULT_ITEMS = [
  {
    id: 0,
    label: 'ড্যাশবোর্ড',
    icon: HomeIcon,
    gradient: 'linear-gradient(135deg, #34d399, #059669)',
    shadow: '0 8px 22px rgba(16, 185, 129, 0.45), 0 3px 8px rgba(16, 185, 129, 0.25)',
    color: '#059669',
  },
  {
    id: 1,
    label: 'ব্যালেন্স',
    icon: WalletIcon,
    gradient: 'linear-gradient(135deg, #60a5fa, #2563eb)',
    shadow: '0 8px 22px rgba(59, 130, 246, 0.45), 0 3px 8px rgba(59, 130, 246, 0.25)',
    color: '#2563eb',
  },
  {
    id: 2,
    label: 'খরচ',
    icon: ChartIcon,
    gradient: 'linear-gradient(135deg, #fb923c, #ea580c)',
    shadow: '0 8px 22px rgba(249, 115, 22, 0.45), 0 3px 8px rgba(249, 115, 22, 0.25)',
    color: '#ea580c',
  },
  {
    id: 3,
    label: 'সদস্য',
    icon: UsersIcon,
    gradient: 'linear-gradient(135deg, #c084fc, #7c3aed)',
    shadow: '0 8px 22px rgba(168, 85, 247, 0.45), 0 3px 8px rgba(168, 85, 247, 0.25)',
    color: '#7c3aed',
  },
  {
    id: 4,
    label: 'বিনিয়োগ',
    icon: InvestIcon,
    gradient: 'linear-gradient(135deg, #f472b6, #db2777)',
    shadow: '0 8px 22px rgba(236, 72, 153, 0.45), 0 3px 8px rgba(236, 72, 153, 0.25)',
    color: '#db2777',
  },
];

export default function CurvedBottomNav({ items = DEFAULT_ITEMS, activeIndex: controlledIndex, onChange }) {
  const [internalIndex, setInternalIndex] = useState(0);
  
  const activeIndex = controlledIndex !== undefined ? controlledIndex : internalIndex;
  const activeItem = items[activeIndex] || items[0];
  const ActiveIcon = activeItem.icon;
  const tabWidthPercent = 100 / items.length;

  const handleClick = (index) => {
    if (controlledIndex === undefined) {
      setInternalIndex(index);
    }
    if (onChange) {
      onChange(index, items[index]);
    }
  };

  return (
    <nav className="curved-nav-container">
      <div className="curved-nav">
        {/* Sliding Active Indicator (Circle + Notch) */}
        <div 
          className="curved-nav__indicator-track"
          style={{ 
            width: `${tabWidthPercent}%`,
            transform: `translateX(${activeIndex * 100}%)` 
          }}
        >
          {/* Top Notch Cutout SVG */}
          <div className="curved-nav__notch">
            <svg viewBox="0 0 100 40" preserveAspectRatio="none" className="curved-nav__notch-svg">
              <path 
                d="M 0,0 C 20,0 25,36 50,36 C 75,36 80,0 100,0 Z" 
                className="curved-nav__notch-fill"
              />
            </svg>
          </div>

          {/* Floating Action Circle */}
          <div 
            className="curved-nav__circle"
            style={{
              background: activeItem.gradient,
              boxShadow: activeItem.shadow,
            }}
          >
            <div className="curved-nav__circle-icon">
              <ActiveIcon />
            </div>
          </div>
        </div>

        {/* Navigation Items */}
        <div className="curved-nav__items">
          {items.map((item, index) => {
            const isActive = activeIndex === index;
            const ItemIcon = item.icon;

            return (
              <button
                key={item.id ?? index}
                type="button"
                onClick={() => handleClick(index)}
                className={`curved-nav__item ${isActive ? 'curved-nav__item--active' : ''}`}
              >
                <div className="curved-nav__icon-wrapper">
                  <span className="curved-nav__icon">
                    <ItemIcon />
                  </span>
                </div>
                <span 
                  className="curved-nav__label"
                  style={isActive ? { color: item.color } : {}}
                >
                  {item.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </nav>
  );
}
