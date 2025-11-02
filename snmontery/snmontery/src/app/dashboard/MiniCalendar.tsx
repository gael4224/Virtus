import React, { useState } from "react";

function getDaysInMonth(year: number, month: number) {
  return new Date(year, month + 1, 0).getDate();
}

function getFirstDayOfWeek(year: number, month: number) {
  return new Date(year, month, 1).getDay();
}

const monthNames = [
  "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
  "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
];

export default function MiniCalendar() {
  const today = new Date();
  const [currentMonth, setCurrentMonth] = useState(today.getMonth());
  const [currentYear, setCurrentYear] = useState(today.getFullYear());

  const daysInMonth = getDaysInMonth(currentYear, currentMonth);
  const firstDay = getFirstDayOfWeek(currentYear, currentMonth);

  const prevMonth = () => {
    if (currentMonth === 0) {
      setCurrentMonth(11);
      setCurrentYear(currentYear - 1);
    } else {
      setCurrentMonth(currentMonth - 1);
    }
  };
  const nextMonth = () => {
    if (currentMonth === 11) {
      setCurrentMonth(0);
      setCurrentYear(currentYear + 1);
    } else {
      setCurrentMonth(currentMonth + 1);
    }
  };

  const days = [];
  for (let i = 0; i < firstDay; i++) {
    days.push(null);
  }
  for (let d = 1; d <= daysInMonth; d++) {
    days.push(d);
  }

  return (
    <div className="mini-calendar">
      <div className="mini-calendar-header">
        <button className="mini-calendar-nav" onClick={prevMonth}>&lt;</button>
        <span className="mini-calendar-title">{monthNames[currentMonth]} {currentYear}</span>
        <button className="mini-calendar-nav" onClick={nextMonth}>&gt;</button>
      </div>
      <div className="mini-calendar-grid" style={{gridTemplateColumns: 'repeat(7, 1fr)'}}>
        {["D", "L", "M", "M", "J", "V", "S"].map((d, i) => (
          <div key={d + i} className="mini-calendar-dayname">{d}</div>
        ))}
        {days.map((d, i) => (
          <div
            key={i}
            className={
              "mini-calendar-cell" +
              (d === today.getDate() && currentMonth === today.getMonth() && currentYear === today.getFullYear() ? " today" : "")
            }
          >
            {d || ""}
          </div>
        ))}
      </div>
    </div>
  );
}
